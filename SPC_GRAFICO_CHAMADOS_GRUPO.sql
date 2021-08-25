CREATE PROCEDURE SP_GRAFICO_CHAMADOS_GRUPO
(
    @CD_USUARIO INT = NULL
)
AS
BEGIN

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    ----------------------------------------------------
                        -- TESTES --
    ----------------------------------------------------

    -- DECLARE 
    -- @CD_USUARIO INT = 114

    ----------------------------------------------------
    -- MONTA TABELA COM GRUPOS QUE O USUÁRIO PERTENCE --
    ----------------------------------------------------

    DROP TABLE IF EXISTS #GRUPOS

    CREATE TABLE #GRUPOS 
    (
    	CD_GRUPO INT IDENTITY,
    	GRUPO_EMPRESA VARCHAR(MAX)
    )

    INSERT INTO #GRUPOS (GRUPO_EMPRESA) 

    (
    	SELECT 
    		GE.GRUPO_EMPRESA 
    	FROM 
    		USUARIO_GRUPO UG
    		LEFT JOIN GRUPO_EMPRESA GE ON GE.CD_GRUPO_EMPRESA = UG.CD_GRUPO
    	WHERE
    		UG.CD_USUARIO = @CD_USUARIO
    )

    ----------------------------------------------------
        -- MONTA VARIÁVEIS PARA A QUERY DINÂMICA --
    ----------------------------------------------------

    BEGIN

    	DECLARE
    	@AUX INT = 1, 									-- Variável de contagem para o loop
    	@SELECT VARCHAR(MAX) = NULL,                    -- variável que vai receber os campos do select (com tratamento de isnull)
    	@PIVOT VARCHAR(MAX) = NULL,                     -- variável que vai receber os campos do pivor (sem o isnull)
    	@AUX2 VARCHAR(MAX) = NULL                       -- Variável que vai receber o nome dos grupos para dar o alias as colunas do isnull

    	WHILE @AUX <=  (SELECT MAX(CD_GRUPO) FROM #GRUPOS)
    
    	BEGIN

    		IF @AUX = 1

    		BEGIN
    	    	SET @AUX2 =(SELECT GRUPO_EMPRESA FROM #GRUPOS WHERE CD_GRUPO = @AUX)
    			SET @SELECT = 'ISNULL('+'['+(SELECT GRUPO_EMPRESA FROM #GRUPOS WHERE CD_GRUPO = @AUX)+']'+',0) AS ' + '['+@AUX2+']'
    			SET @PIVOT = '['+(SELECT GRUPO_EMPRESA FROM #GRUPOS WHERE CD_GRUPO = @AUX)+']'
    
    
    		END

    		ELSE

    		BEGIN
    	    	SET @AUX2 =(SELECT GRUPO_EMPRESA FROM #GRUPOS WHERE CD_GRUPO = @AUX)
    			SET @SELECT = @SELECT + ','+'ISNULL('+'['+(SELECT GRUPO_EMPRESA FROM #GRUPOS WHERE CD_GRUPO= @AUX)+']'+',0) AS ' + '['+@AUX2+']'
    			SET @PIVOT =  @PIVOT + ','+'['+(SELECT GRUPO_EMPRESA FROM #GRUPOS WHERE CD_GRUPO= @AUX)+']'

    		END
    		SET @AUX += 1

    	END

    ----------------------------------------------------------------------------------------
        -- CARREGA A VARIÁVEL DA QUERY DINÂMICA PASSANDO AS VARIÁVEIS MONTADAS ACIMA --
    ----------------------------------------------------------------------------------------

    	DECLARE @QUERY VARCHAR(MAX)  =
    
    	'SELECT
    	    ' + (@SELECT) + '
    
    	FROM
    
    	(SELECT 
    	COUNT(C.CD_CHAMADO) AS QTD,
    	GE.GRUPO_EMPRESA
    
    	FROM 
    	SOMA_CHAMADO C
    	LEFT JOIN SOMA_GRUPO_EMPRESA GE ON GE.CD_GRUPO_EMPRESA = C.CD_GRUPO_EMPRESA
    	GROUP BY GRUPO_EMPRESA) AS A
    
    	PIVOT(
    	    SUM(QTD)
    	    FOR
    	    [GRUPO_EMPRESA]
    	     IN(' + @PIVOT + ')) AS PV'
    
    END

    -------------------------------------------
    -- EXECUTA A QUERY E EXIBE OS RESULTADOS --
    -------------------------------------------

    EXEC (@QUERY)

END




 