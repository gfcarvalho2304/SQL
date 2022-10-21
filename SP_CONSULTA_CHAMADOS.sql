CREATE PROCEDURE [dbo].[SP_CONSULTA_CHAMADOS]
(
	@CD_USUARIO INT = NULL,
	@DH_INICIO DATETIME = NULL,
	@DH_FIM DATETIME = NULL,
	@CD_EMPRESA VARCHAR(MAX) = NULL,
	@CD_GRUPO VARCHAR(MAX) = NULL,
	@CD_STATUS_CHAMADO VARCHAR(MAX) = NULL,
	@CD_FILA VARCHAR(MAX) = NULL
)
AS

BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    -- EXEMPLO DE UMA QUERY DE UM RELATÓRIO DE CHAMADOS --
	
	
	-------------
	-- TESTES --
	-------------
	
	-- DROP TABLE IF EXISTS #PERMISSOES
    
    -- DECLARE
	
	-- @CD_USUARIO INT = 107,
	-- @DH_INICIO DATETIME = NULL,
	-- @DH_FIM DATETIME = NULL,
	-- @CD_EMPRESA VARCHAR(MAX) = NULL,
	-- @CD_GRUPO VARCHAR(MAX) = NULL,
	-- @CD_STATUS_CHAMADO VARCHAR(MAX) = NULL,
	-- @CD_FILA VARCHAR(MAX) = NULL
	
	---------------------------------------------------------------------
	-- AJUSTA DATA PARA PEGAR REGISTROS ATE O FINAL DO DIA DA DATA FIM --
	---------------------------------------------------------------------
	
	SELECT @DH_FIM = CASE WHEN @DH_FIM IS NOT NULL THEN @DH_FIM + '23:59:59'ELSE @DH_FIM END

	
	--------------------------------------------------------------------
			-- BUSCA GRUPO, EMPRESA E PERFIL DO USUÁRIO LOGADO --
	--------------------------------------------------------------------
	
    DROP TABLE IF EXISTS #GRUPOS 
    --(Cria uma tabela temporária com todos os grupos que o usuário pertence)
    SELECT CD_GRUPO INTO #GRUPOS FROM USUARIO_GRUPO WHERE CD_USUARIO = @CD_USUARIO 
    
	 /*(Procura o código da empresa que o usuário pertence na tabela de relação grupo x empresa
      a partir dos códigos dos grupos recuperados na tabela temporária #GRUPOS)*/
   
    DECLARE @CD_EMPRESA_USUARIO INT = (SELECT TOP 1 CD_EMPRESA FROM GRUPO_EMPRESA WHERE CD_GRUPO_EMPRESA IN (SELECT CD_GRUPO FROM #GRUPOS)) 
	DECLARE @CD_PERFIL_USUARIO INT = (SELECT TOP 1 CD_PERFIL FROM USUARIO_PERFIL WHERE CD_USUARIO = @CD_USUARIO)
	
    ------------------------------------------------------------------------
			-- GERA TABELA TEMPORARIA COM PERMISSOES DO USUARIO --
	------------------------------------------------------------------------

	
	SELECT 
		P.CD_PERMISSAO,                 /* Consulta em uma tabela de permissões todos os códigos de permissão que estão associados ao grupo
		P.NOME AS 'PERMISSAO'              que o usuário pertence */
	
	INTO 
		#PERMISSOES
	FROM 
		PERMISSAO_PERFIL PP
	INNER JOIN PERMISSAO P ON P.CD_PERMISSAO = PP.CD_PERMISSAO
	WHERE 
		CD_PERFIL = @CD_PERFIL_USUARIO

	
    
    --------------------------------------------------------------------
						-- USUÁRIO INTERNO --
	--------------------------------------------------------------------
	

    IF EXISTS (SELECT * FROM #PERMISSOES WHERE CD_PERMISSAO = 4327)	-- (Permissão 4327 significa que o usuário é interno)

	BEGIN
	
		SELECT
			SC.CODIGO,
			SS.SISTEMA,
			SM.MODULO,
			SOL.SOLICITACAO,
			FL.GRUPO_EMPRESA                                                                            AS 'FILA',
			ST.STATUS_CHAMADO                                                                           AS 'STATUS',
			GUA.EMPRESA,
            SGE.GRUPO_EMPRESA                                                                           AS 'CLIENTE',
			SC.DATA_HORA_ABERTURA                                                                       AS 'DATA ABERTURA',
			SC.DH_INICIO_ATENDIMENTO                                                                    AS 'INICIO ATENDIMENTO',
			SC.DH_FIM_ATENDIMENTO                                                                       AS 'FIM ATENDIMENTO',
			UA.NOME                                                                                     AS 'SOLICITANTE',
			UR.NOME                                                                                     AS 'RESPONSAVEL',
			dbo.FN_SEGUNDOS_EM_HORAS(DATEDIFF(SECOND,SC.DATA_HORA_ABERTURA,SC.DH_INICIO_ATENDIMENTO))   AS 'TEMPO PARA INICIAR',
            /*Busca a diferença entre a data_hora da abertura e da data_hora do início do atendimento em segundos,
            e em seguida a função FN_SEGUNDOS_EM_HORAS converte para horas no formato hh:mm:ss */
			dbo.FN_SEGUNDOS_EM_HORAS(DATEDIFF(SECOND,SC.DH_INICIO_ATENDIMENTO,DH_FIM_ATENDIMENTO))      AS 'TEMPO PARA SOLUÇÃO'
		
		FROM 
			CHAMADO SC
		
            LEFT JOIN SISTEMA SS ON SS.CD_SISTEMA = SC.CD_SISTEMA
		    LEFT JOIN MODULO SM ON SM.CD_MODULO = SC.CD_MODULO
		    LEFT JOIN SOLICITACAO SOL ON SOL.CD_SOLICITACAO = SC.CD_SOLICITACAO
		    LEFT JOIN GRUPO_EMPRESA FL ON FL.CD_GRUPO_EMPRESA = SC.CD_FILA
		    LEFT JOIN STATUS_CHAMADO ST ON ST.CD_STATUS_CHAMADO = SC.CD_STATUS_CHAMADO
		    LEFT JOIN EMPRESA SE ON SE.CD_EMPRESA = SC.CD_EMPRESA
		    LEFT JOIN GRUPO_EMPRESA SGE ON SGE.CD_GRUPO_EMPRESA = SC.CD_GRUPO_EMPRESA
		    
            OUTER APPLY
            (
                SELECT C.EMPRESA FROM GRUPO_EMPRESA A
                LEFT JOIN USUARIO_GRUPO B ON B.CD_GRUPO = A.CD_GRUPO_EMPRESA
                LEFT JOIN EMPRESA C ON C.CD_EMPRESA = A.CD_EMPRESA
                WHERE B.CD_USUARIO = SC.CD_USUARIO_ABERTURA

            
            ) GUA
            
         
            
            
            LEFT JOIN USUARIO UA ON UA.CD_USUARIO = SC.CD_USUARIO_ABERTURA
		    LEFT JOIN USUARIO UR ON UR.CD_USUARIO = SC.CD_RESPONSAVEL
		
		WHERE
		
		    ((@DH_INICIO IS NULL) OR SC.DATA_HORA_ABERTURA BETWEEN @DH_INICIO AND @DH_FIM)
		    AND ((@CD_FILA IS NULL) OR (SC.CD_FILA IN (SELECT VALUE FROM STRING_SPLIT(@CD_FILA,','))))
		    AND ((@CD_STATUS_CHAMADO IS NULL) OR (SC.CD_STATUS_CHAMADO IN (SELECT VALUE FROM STRING_SPLIT(@CD_STATUS_CHAMADO,','))))
		    AND ((@CD_EMPRESA IS NULL) OR (SC.CD_EMPRESA IN (SELECT VALUE FROM STRING_SPLIT(@CD_EMPRESA,','))))
		    AND ((@CD_GRUPO IS NULL) OR (SC.CD_GRUPO_EMPRESA IN (SELECT VALUE FROM STRING_SPLIT(@CD_GRUPO,','))))
		

	END

	--------------------------------------------------------------------
							-- CLIENTE --
	--------------------------------------------------------------------
	
	ELSE

	BEGIN

	SELECT
			SC.CODIGO,
			SS.SISTEMA,
			SM.MODULO,
			SOL.SOLICITACAO,
			FL.GRUPO_EMPRESA            AS 'FILA',
			ST.STATUS_CHAMADO_EXTERNO   AS 'STATUS',
			SE.EMPRESA,
			SGE.GRUPO_EMPRESA           AS 'GRUPO',
			SC.DATA_HORA_ABERTURA       AS 'DATA ABERTURA',
			SC.DH_INICIO_ATENDIMENTO    AS 'INICIO ATENDIMENTO',
			SC.DH_FIM_ATENDIMENTO       AS 'FIM ATENDIMENTO',
			UA.NOME                     AS 'SOLICITANTE'
			
		
		FROM 
			CHAMADO SC
		
            LEFT JOIN SISTEMA SS ON SS.CD_SISTEMA = SC.CD_SISTEMA
		    LEFT JOIN MODULO SM ON SM.CD_MODULO = SC.CD_MODULO
		    LEFT JOIN SOLICITACAO SOL ON SOL.CD_SOLICITACAO = SC.CD_SOLICITACAO
		    LEFT JOIN GRUPO_EMPRESA FL ON FL.CD_GRUPO_EMPRESA = SC.CD_FILA
		    LEFT JOIN STATUS_CHAMADO ST ON ST.CD_STATUS_CHAMADO = SC.CD_STATUS_CHAMADO
		    LEFT JOIN EMPRESA SE ON SE.CD_EMPRESA = SC.CD_EMPRESA
		    LEFT JOIN SOMA_GRUPO_EMPRESA SGE ON SGE.CD_GRUPO_EMPRESA = SC.CD_GRUPO_EMPRESA
		    LEFT JOIN USUARIO UA ON UA.CD_USUARIO = SC.CD_USUARIO_ABERTURA
		    LEFT JOIN USUARIO UR ON UR.CD_USUARIO = SC.CD_RESPONSAVEL
		
		WHERE
		
		    ((@DH_INICIO IS NULL) OR SC.DATA_HORA_ABERTURA BETWEEN @DH_INICIO AND @DH_FIM)
		    AND ((@CD_FILA IS NULL) OR (SC.CD_FILA IN (SELECT VALUE FROM STRING_SPLIT(@CD_FILA,','))))
		    AND ((@CD_STATUS_CHAMADO IS NULL) OR (SC.CD_STATUS_CHAMADO IN (SELECT VALUE FROM STRING_SPLIT(@CD_STATUS_CHAMADO,','))))
		    AND ((@CD_EMPRESA IS NULL) OR (SC.CD_EMPRESA IN (SELECT VALUE FROM STRING_SPLIT(@CD_EMPRESA,','))))
		    AND ((@CD_GRUPO IS NULL) OR (SC.CD_GRUPO_EMPRESA IN (SELECT VALUE FROM STRING_SPLIT(@CD_GRUPO,','))))
		    --AND SC.CD_EMPRESA = @CD_EMPRESA_USUARIO REMOV. 08/06
            AND SC.CD_GRUPO_EMPRESA IN (SELECT CD_GRUPO FROM #GRUPOS) 
            AND SC.CD_USUARIO_ABERTURA NOT IN -- usuário externo não enxerga chamados abertos por funcionários da empresa prestadora
            (
                SELECT CD_USUARIO FROM SOMA_USUARIO_GRUPO WHERE CD_GRUPO IN 
                (
                    SELECT CD_GRUPO_EMPRESA FROM GRUPO_EMPRESA WHERE CD_EMPRESA = 8
                )
            )


	END

END


