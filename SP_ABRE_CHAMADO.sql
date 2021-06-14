
CREATE PROCEDURE [dbo].[SPI_CHAMADO] 
 (

	
 	@CD_SISTEMA INT = NULL,
 	@CD_MODULO INT = NULL,
 	@CD_SOLICITACAO INT = NULL,
 	@CD_MOTIVO_CANCELAMENTO INT = NULL,
 	@OBS_MOTIVO_CANCELAMENTO VARCHAR(MAX) = NULL,
 	@DATA_HORA_ABERTURA DATETIME = NULL,
 	@CD_USUARIO INT = NULL,
 	@DESCRICAO VARCHAR(MAX) = NULL,
 	@DH_FIM_ATENDIMENTO DATETIME = NULL,
 	@DH_ALTERACAO DATETIME = NULL,
 	@CD_USUARIO_FINALIZADO INT = NULL,
 	@CD_USUARIO_CANCELADO INT = NULL,
 	@CD_EMPRESA INT = NULL,
    @CD_CLIENTE INT = NULL,
    @MOTIVO VARCHAR(MAX) = NULL,
 	@CD_APROVACAO INT = NULL,
 	@MOTIVO_REPROVACAO VARCHAR(MAX) = NULL,
 	@MOTIVO_CONCLUSAO VARCHAR(MAX) = NULL,
 	@RESPONSAVEL_REPROVACAO INT = NULL,
 	@RESPONSAVEL_CONCLUSAO INT = NULL,
 	@MOTIVO_APROVACAO VARCHAR(MAX) = NULL,
 	@RESPONSAVEL_APROVACAO INT = NULL,
 	@MOTIVO_REABERTURA INT = NULL,
 	@RESPONSAVEL_REABERTURA INT = NULL,
 	@CD_PRIORIDADE INT = NULL

 )

 AS
BEGIN

    /*Objetivo: Inserir um novo chamado em uma tabela de chamados */

	SET TRAN ISOLATION LEVEL READ UNCOMMITTED 
	
	------------------------------------------
					-- DEBUG --
	------------------------------------------
	
	-- DECLARE

	-- --@CD_STATUS_CHAMADO INT = NULL,
	-- @CD_SISTEMA INT = 2,
	-- @CD_MODULO INT = 3,
	-- @CD_SOLICITACAO INT = 6,
	-- @CD_MOTIVO_CANCELAMENTO INT = NULL,
	-- @OBS_MOTIVO_CANCELAMENTO VARCHAR(MAX) = NULL,
	-- @DATA_HORA_ABERTURA DATETIME = NULL,
	-- @CD_USUARIO INT = 4,
	-- @DESCRICAO VARCHAR(MAX) = 'TESTE INCLUSAO USUARIO INTERNO 2',
	-- @DH_FIM_ATENDIMENTO DATETIME = NULL,
	-- @DH_ALTERACAO DATETIME = NULL,
	-- @CD_USUARIO_FINALIZADO INT = NULL,
	-- @CD_USUARIO_CANCELADO INT = NULL,
	-- @CD_EMPRESA INT = NULL,
	-- --@CD_GRUPO_EMPRESA INT = NULL,
	-- @CD_CLIENTE INT = 28,
    -- @MOTIVO VARCHAR(MAX) = NULL,
	-- @CD_APROVACAO INT = NULL,
	-- @MOTIVO_REPROVACAO VARCHAR(MAX) = NULL,
	-- @MOTIVO_CONCLUSAO VARCHAR(MAX) = NULL,
	-- @RESPONSAVEL_REPROVACAO INT = NULL,
	-- @RESPONSAVEL_CONCLUSAO INT = NULL,
	-- @MOTIVO_APROVACAO VARCHAR(MAX) = NULL,
	-- @RESPONSAVEL_APROVACAO INT = NULL,
	-- @MOTIVO_REABERTURA INT = NULL,
	-- @RESPONSAVEL_REABERTURA INT = NULL,
	-- @CD_PRIORIDADE INT = NULL
	
	----------------------------------------------	
	-- BUSCA O GRUPO DO USUÁRIO QUE FEZ O LOGIN --
	----------------------------------------------	
	
	--DECLARE @CD_GRUPO INT = (SELECT TOP 1 CD_GRUPO FROM USUARIO_GRUPO WHERE CD_USUARIO = @CD_USUARIO)

    DROP TABLE IF EXISTS #GRUPOS
    SELECT CD_GRUPO INTO #GRUPOS FROM USUARIO_GRUPO WHERE CD_USUARIO = @CD_USUARIO


	DECLARE @CD_GRUPO INT = (SELECT TOP 1 CD_GRUPO FROM #GRUPOS)
    DECLARE @CD_EMPRESA_USUARIO_LOGADO INT = (SELECT TOP 1 CD_EMPRESA FROM GRUPO_EMPRESA WHERE CD_GRUPO_EMPRESA IN(SELECT CD_GRUPO FROM #GRUPOS))
    DECLARE @CD_EMPRESA_CLIENTE INT = (SELECT TOP 1 CD_EMPRESA FROM GRUPO_EMPRESA WHERE CD_GRUPO_EMPRESA = @CD_CLIENTE)

	
	----------------------------------------------	        /*De acordo com regra definida, o codigo do chamado deve conter a data de abertura
		   -- GERA 4 NÚMEROS ALEATÓRIOS --                    concatenada à quatro números aleatórios */
	----------------------------------------------	
   
    DECLARE @A INT = ABS (CHECKSUM(NEWID())) 
    DECLARE @B INT = ABS (CHECKSUM(NEWID())) 
    DECLARE @C INT = ABS (CHECKSUM(NEWID())) 
    DECLARE @D INT = ABS (CHECKSUM(NEWID())) 

	----------------------------------------------	
	   -- COMBINA OS 4 NÚMEROS EM UMA STRING --
	----------------------------------------------	

	DECLARE @ALEATORIO VARCHAR(4) = CONCAT(CAST(@A AS VARCHAR), CAST(@B AS VARCHAR), CAST(@C AS VARCHAR),CAST(@D AS VARCHAR))

	----------------------------------------------	
	   -- GERA O CODIGO DO CHAMADO --
	----------------------------------------------	
	
	DECLARE @CODIGO VARCHAR(MAX) = REPLACE(REPLACE(REPLACE(FORMAT(GETDATE() , 'dd/MM/yyyy HH:mm:ss'),'/',''),':',''),' ','') +'-' + @ALEATORIO 
		
	----------------------------------------------	
	  -- CHAMADO ABERTO POR FUNCIONARIO DO RH --
	----------------------------------------------
    
    IF @CD_EMPRESA_USUARIO_LOGADO = 8 AND @CD_SISTEMA = 16

	BEGIN
	
		INSERT INTO CHAMADO 
		(
		
			CD_STATUS_CHAMADO, 
			CD_SISTEMA,
			CD_MODULO,
			CD_SOLICITACAO,
			CD_MOTIVO_CANCELAMENTO,
			OBS_MOTIVO_CANCELAMENTO,
			DATA_HORA_ABERTURA,
			CD_USUARIO_ABERTURA,
			DESCRICAO,
			DH_FIM_ATENDIMENTO,
			DH_ALTERACAO,
			CD_USUARIO_FINALIZADO,
			CD_USUARIO_CANCELADO,
			CD_RESPONSAVEL,
			CD_EMPRESA,
           -- CD_GRUPO_USUARIO_ABERTURA, --@cd_grupo (grupo do usuário logado)
			MOTIVO,
			CD_APROVACAO,
			MOTIVO_REPROVACAO,
			MOTIVO_CONCLUSAO,
			RESPONSAVEL_REPROVACAO,
			RESPONSAVEL_CONCLUSAO,
			MOTIVO_APROVACAO,
			RESPONSAVEL_APROVACAO,
			MOTIVO_REABERTURA,
			RESPONSAVEL_REABERTURA,
			CD_PRIORIDADE,
			CD_GRUPO_EMPRESA, --@cd_cliente (grupo do cliente passado pela tela)
			TICKET,
			CD_FILA
		)
		
		VALUES

		(   
			1, -- CHAMADO NASCE COM STATUS AGUARDANDO ATENDIMENTO
			@CD_SISTEMA,
			@CD_MODULO,
			@CD_SOLICITACAO,
			@CD_MOTIVO_CANCELAMENTO,
			@OBS_MOTIVO_CANCELAMENTO,
			GETDATE(),
			@CD_USUARIO,
			@DESCRICAO,
			@DH_FIM_ATENDIMENTO,
			GETDATE(),
			@CD_USUARIO_FINALIZADO,
			@CD_USUARIO_CANCELADO,
			NULL, -- chamado inicia com responsável nulo
			ISNULL(@CD_EMPRESA_CLIENTE,@CD_EMPRESA_USUARIO_LOGADO),
            --@CD_GRUPO,
			@MOTIVO,
			@CD_APROVACAO,
			@MOTIVO_REPROVACAO,
			@MOTIVO_CONCLUSAO,
			@RESPONSAVEL_REPROVACAO,
			@RESPONSAVEL_CONCLUSAO,
			@MOTIVO_APROVACAO,
			@RESPONSAVEL_APROVACAO,
			@MOTIVO_REABERTURA,
			@RESPONSAVEL_REABERTURA,
			@CD_PRIORIDADE,
			@CD_CLIENTE,
			@CODIGO,
			49 -- CASO CHAMADO SEJA DO SISTEMA RH JA NASCE NA FILA DO RH

		)
	END



    ----------------------------------------------------
      -- CHAMADO ABERTO POR FUNCIONARIO ESPECIALISTA  --
    ----------------------------------------------------

	ELSE IF @CD_EMPRESA_USUARIO_LOGADO = 8 AND @CD_SISTEMA <> 16

	BEGIN 
	
		INSERT INTO CHAMADO 
		(
		
			CD_STATUS_CHAMADO,
			CD_SISTEMA,
			CD_MODULO,
			CD_SOLICITACAO,
			CD_MOTIVO_CANCELAMENTO,
			OBS_MOTIVO_CANCELAMENTO,
			DATA_HORA_ABERTURA,
			CD_USUARIO_ABERTURA, --@cd_grupo (grupo do usuário logado)
			DESCRICAO,
			DH_FIM_ATENDIMENTO,
			DH_ALTERACAO,
			CD_USUARIO_FINALIZADO,
			CD_USUARIO_CANCELADO,
			CD_RESPONSAVEL,
			CD_EMPRESA, --@cd_empresa_cliente
           -- CD_GRUPO_USUARIO_ABERTURA, 
			MOTIVO,
			CD_APROVACAO,
			MOTIVO_REPROVACAO,
			MOTIVO_CONCLUSAO,
			RESPONSAVEL_REPROVACAO,
			RESPONSAVEL_CONCLUSAO,
			MOTIVO_APROVACAO,
			RESPONSAVEL_APROVACAO,
			MOTIVO_REABERTURA,
			RESPONSAVEL_REABERTURA,
			CD_PRIORIDADE,
			CD_GRUPO_EMPRESA, --@cd_cliente (grupo do cliente passado pela tela)
			TICKET,
			CD_FILA
		)
		
		VALUES

		(   
			1, -- CHAMADO NASCE COM STATUS AGUARDANDO ATENDIMENTO
			@CD_SISTEMA,
			@CD_MODULO,
			@CD_SOLICITACAO,
			@CD_MOTIVO_CANCELAMENTO,
			@OBS_MOTIVO_CANCELAMENTO,
			GETDATE(),
			@CD_USUARIO,
			@DESCRICAO,
			@DH_FIM_ATENDIMENTO,
			GETDATE(),
			@CD_USUARIO_FINALIZADO,
			@CD_USUARIO_CANCELADO,
			NULL, -- chamado inicia com responsável nulo
			@CD_EMPRESA_CLIENTE,
            --@CD_GRUPO,
			@MOTIVO,
			@CD_APROVACAO,
			@MOTIVO_REPROVACAO,
			@MOTIVO_CONCLUSAO,
			@RESPONSAVEL_REPROVACAO,
			@RESPONSAVEL_CONCLUSAO,
			@MOTIVO_APROVACAO,
			@RESPONSAVEL_APROVACAO,
			@MOTIVO_REABERTURA,
			@RESPONSAVEL_REABERTURA,
			@CD_PRIORIDADE,
			@CD_CLIENTE,
			@CODIGO,
			NULL -- CHAMADO NASCE SEM FILA

		)
	END

	ELSE IF (SELECT COUNT(*) FROM #GRUPOS) = 1

    -----------------------------------------------------------------------------
    -- CHAMADO ABERTO POR CLIENTE QUE PERTENCE A UM ÚNUCO GRUPO EM SUA EMPRESA --
    -----------------------------------------------------------------------------

	BEGIN
	
		INSERT INTO CHAMADO 
		(
		
			CD_STATUS_CHAMADO,
			CD_SISTEMA,
			CD_MODULO,
			CD_SOLICITACAO,
			CD_MOTIVO_CANCELAMENTO,
			OBS_MOTIVO_CANCELAMENTO,
			DATA_HORA_ABERTURA,
			CD_USUARIO_ABERTURA, --@cd_grupo (grupo do usuário logado)
			DESCRICAO,
			DH_FIM_ATENDIMENTO,
			DH_ALTERACAO,
			CD_USUARIO_FINALIZADO,
			CD_USUARIO_CANCELADO,
			CD_RESPONSAVEL,
			CD_EMPRESA, -- @cd_empresa_usuario_logado
            --CD_GRUPO_USUARIO_ABERTURA,
			MOTIVO,
			CD_APROVACAO,
			MOTIVO_REPROVACAO,
			MOTIVO_CONCLUSAO,
			RESPONSAVEL_REPROVACAO,
			RESPONSAVEL_CONCLUSAO,
			MOTIVO_APROVACAO,
			RESPONSAVEL_APROVACAO,
			MOTIVO_REABERTURA,
			RESPONSAVEL_REABERTURA,
			CD_PRIORIDADE,
			CD_GRUPO_EMPRESA, --@cd_grupo (grupo do usuário logado ja que está sendo aberto pelo cliente)
			TICKET,
			CD_FILA
		)
		
		VALUES

		(   
			1, -- CHAMADO NASCE COM STATUS AGUARDANDO ATENDIMENTO
			@CD_SISTEMA,
			@CD_MODULO,
			@CD_SOLICITACAO,
			@CD_MOTIVO_CANCELAMENTO,
			@OBS_MOTIVO_CANCELAMENTO,
			GETDATE(),
			@CD_USUARIO,
			@DESCRICAO,
			@DH_FIM_ATENDIMENTO,
			GETDATE(),
			@CD_USUARIO_FINALIZADO,
			@CD_USUARIO_CANCELADO,
			NULL, -- chamado inicia com responsável nulo
			@CD_EMPRESA_USUARIO_LOGADO, --cd_empresa do cliente
            --@CD_GRUPO,
			@MOTIVO,
			@CD_APROVACAO,
			@MOTIVO_REPROVACAO,
			@MOTIVO_CONCLUSAO,
			@RESPONSAVEL_REPROVACAO,
			@RESPONSAVEL_CONCLUSAO,
			@MOTIVO_APROVACAO,
			@RESPONSAVEL_APROVACAO,
			@MOTIVO_REABERTURA,
			@RESPONSAVEL_REABERTURA,
			@CD_PRIORIDADE,
			@CD_GRUPO,
			@CODIGO,
			NULL -- CHAMADO NASCE SEM FILA

		)
	END

     -------------------------------------------------------------------------------
     -- CHAMADO ABERTO POR CLIENTE QUE PERTENCE A MAIS DE UM GRUPO EM SUA EMPRESA --
     -------------------------------------------------------------------------------
    ELSE
	
    BEGIN
	
		INSERT INTO CHAMADO 
		(
		
			CD_STATUS_CHAMADO,
			CD_SISTEMA,
			CD_MODULO,
			CD_SOLICITACAO,
			CD_MOTIVO_CANCELAMENTO,
			OBS_MOTIVO_CANCELAMENTO,
			DATA_HORA_ABERTURA,
			CD_USUARIO_ABERTURA, --@cd_grupo (grupo do usuário logado)
			DESCRICAO,
			DH_FIM_ATENDIMENTO,
			DH_ALTERACAO,
			CD_USUARIO_FINALIZADO,
			CD_USUARIO_CANCELADO,
			CD_RESPONSAVEL,
			CD_EMPRESA, -- @cd_empresa_usuario_logado
            --CD_GRUPO_USUARIO_ABERTURA,
			MOTIVO,
			CD_APROVACAO,
			MOTIVO_REPROVACAO,
			MOTIVO_CONCLUSAO,
			RESPONSAVEL_REPROVACAO,
			RESPONSAVEL_CONCLUSAO,
			MOTIVO_APROVACAO,
			RESPONSAVEL_APROVACAO,
			MOTIVO_REABERTURA,
			RESPONSAVEL_REABERTURA,
			CD_PRIORIDADE,
			CD_GRUPO_EMPRESA, --@cd_grupo (grupo do usuário logado ja que está sendo aberto pelo cliente)
			TICKET,
			CD_FILA
		)
		
		VALUES

		(   
			1, -- CHAMADO NASCE COM STATUS AGUARDANDO ATENDIMENTO
			@CD_SISTEMA,
			@CD_MODULO,
			@CD_SOLICITACAO,
			@CD_MOTIVO_CANCELAMENTO,
			@OBS_MOTIVO_CANCELAMENTO,
			GETDATE(),
			@CD_USUARIO,
			@DESCRICAO,
			@DH_FIM_ATENDIMENTO,
			GETDATE(),
			@CD_USUARIO_FINALIZADO,
			@CD_USUARIO_CANCELADO,
			NULL, -- chamado inicia com responsável nulo
			@CD_EMPRESA_USUARIO_LOGADO, --cd_empresa do cliente
            --@CD_GRUPO,
			@MOTIVO,
			@CD_APROVACAO,
			@MOTIVO_REPROVACAO,
			@MOTIVO_CONCLUSAO,
			@RESPONSAVEL_REPROVACAO,
			@RESPONSAVEL_CONCLUSAO,
			@MOTIVO_APROVACAO,
			@RESPONSAVEL_APROVACAO,
			@MOTIVO_REABERTURA,
			@RESPONSAVEL_REABERTURA,
			@CD_PRIORIDADE,
			@CD_CLIENTE,
			@CODIGO,
			NULL -- CHAMADO NASCE SEM FILA

		)
	END
	
    ----------------------------------------------------
             -- CAPTURA O CD DO CHAMADO  --
    ----------------------------------------------------
    
	DECLARE @CD_CHAMADO INT
	SELECT @CD_CHAMADO = SCOPE_IDENTITY()

	
    ----------------------------------------------------
       -- RETORNA A LINHA DO CHAMADO RECÉM CRIADO  --
    ----------------------------------------------------
	
	SELECT * FROM CHAMADO WHERE CD_CHAMADO = @CD_CHAMADO

	----------------------------------------------------
		-- INSERE CHAMADO NA TABELA DE HISTORICO --
	----------------------------------------------------

	INSERT INTO CHAMADO_HISTORICO 
	(
		 CD_CHAMADO
		,CD_STATUS_CHAMADO
		,CD_SISTEMA
		,CD_MODULO
		,CD_SOLICITACAO
		,CD_MOTIVO_CANCELAMENTO
		,OBS_MOTIVO_CANCELAMENTO
		,DATA_HORA_ABERTURA
		,CD_USUARIO_ABERTURA
		,DESCRICAO
		,DH_FIM_ATENDIMENTO
		,DH_ALTERACAO
		,CD_USUARIO_FINALIZADO
		,CD_USUARIO_CANCELADO
		,CD_RESPONSAVEL
		,CD_EMPRESA
        --,CD_GRUPO_USUARIO_ABERTURA
		,MOTIVO
		,CD_APROVACAO
		,MOTIVO_REPROVACAO
		,MOTIVO_CONCLUSAO
		,RESPONSAVEL_REPROVACAO
		,RESPONSAVEL_CONCLUSAO
		,MOTIVO_APROVACAO
		,RESPONSAVEL_APROVACAO
		,MOTIVO_REABERTURA
		,RESPONSAVEL_REABERTURA
		,CD_PRIORIDADE
		,CD_FILA
		,CD_GRUPO_EMPRESA
		,TICKET

	)
	
	
	SELECT   
		 CD_CHAMADO
		,CD_STATUS_CHAMADO
		,CD_SISTEMA
		,CD_MODULO
		,CD_SOLICITACAO
		,CD_MOTIVO_CANCELAMENTO
		,OBS_MOTIVO_CANCELAMENTO
		,DATA_HORA_ABERTURA
		,CD_USUARIO_ABERTURA
		,DESCRICAO
		,DH_FIM_ATENDIMENTO
		,DH_ALTERACAO
		,CD_USUARIO_FINALIZADO
		,CD_USUARIO_CANCELADO
		,CD_RESPONSAVEL
		,CD_EMPRESA
        --,CD_GRUPO_USUARIO_ABERTURA
		,MOTIVO
		,CD_APROVACAO
		,MOTIVO_REPROVACAO
		,MOTIVO_CONCLUSAO
		,RESPONSAVEL_REPROVACAO
		,RESPONSAVEL_CONCLUSAO
		,MOTIVO_APROVACAO
		,RESPONSAVEL_APROVACAO
		,MOTIVO_REABERTURA
		,RESPONSAVEL_REABERTURA
		,CD_PRIORIDADE
		,CD_FILA
		,CD_GRUPO_EMPRESA
		,TICKET
	
	FROM 
		CHAMADO 
	
	WHERE 
		CD_CHAMADO = @CD_CHAMADO

END

