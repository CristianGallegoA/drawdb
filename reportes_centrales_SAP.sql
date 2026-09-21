-- 1_informacion_BM_DC
-- ## INFORMACION DE BAJOS MONTOS PARA REPORTAR A DATACREDITO CIFIN
/* Genera la informacion para reportar a Datacredito de los productos de Bajos Montos */
SELECT 
    TIPO_ARCHIVO, 
    FECHA_REPORTE, 
    COD_PRODUCTO,
    PRODUCTO, 
    CODETIPONEGOCIO,
    TIPO_NEGOCIO, 
    FECHA_EJECUCION, 
    CREDITO, 
    FECHA_INICIO, 
    FECHA_VENC, 
    VLRDESEMBOLSO, 
    SALDOK, 
    CUOTAS, 
    CUOTASCANCELADAS, 
    CUOTASMORA, 
    ESTADO, 
    SUBESTADO, 
    TIPO_IDENT, 
    CEDULA, 
    NOMBRE, 
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA, 
    DIASMORA, 
    FECHALIMITE, 
    FECHAULTIMOPAGO, 
    VALORMORA, 
    DIACORTE, 
    COD_CIUDADCORR, 
    CIUDADCORR, 
    DEPARTAMENTOCORR, 
    COD_DEPARTAMENTOCORR, 
    TELEFONO, 
    MOVIL, 
    CORREO_ELECTRONICO, 
    DIRECCION,
	--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
        SELECT 
        'BajosMontos' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE 
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '13'       
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
             ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION, 
              TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
        TRANSLATE(
            TRIM(REGEXP_REPLACE(REPLACE(
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                    DIR.CONINFORMACION, 
                                    TER.TERDIRECCION,'0'))
                ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),'  ',' ')
            ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
        ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
    ,1,50) AS DIRECCION
--------------------------------------------------------------------------------
    ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP 
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO 
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS 
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP 
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO 
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT 
                CREDITO
                ,FECHA_INGRESO 
            FROM 
            ( 
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID 
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0 
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada  Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION 
--------------------------------------------------------------------------------
        LEFT JOIN 
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM ( 
                (SELECT 
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK, 
                    CON.CONPERNATJUR, 
                    CON.CONINFORMACION 
                FROM PRDCCION.EE_CONTACTO CON 
                WHERE CONFORMACONTACTO = 'DIR' 
                    AND CONESTADO = 'ACT' 
                    AND CPCTIPOGESTIONADO = 'CLIE' 
                    AND CONAPLICACORRESPONDENCIA = '1' 
                ) 
              ) WHERE RNK=1)DIR 
        ON DIR.CONPERNATJUR = TER.TERUUID 
--------------------------------------------------------------------------------
        LEFT JOIN 
-- INFORMACION DEL CELULAR -----------------------------------------------------
        (SELECT * FROM ( 
            (SELECT 
                ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK, 
                CON.CONPERNATJUR, 
                CON.CONINFORMACION 
            FROM PRDCCION.EE_CONTACTO CON 
            WHERE CONFORMACONTACTO = 'CEL' 
                AND CONESTADO = 'ACT' 
                AND CPCTIPOGESTIONADO = 'CLIE' 
                AND CONCONTACTOCONFIRMADO = '1' 
            ) 
          ) WHERE RNK=1)CEL 
    ON CEL.CONPERNATJUR = TER.TERUUID 
--------------------------------------------------------------------------------
        LEFT JOIN 
-- INFORMACION DE CORREO -------------------------------------------------------
        (SELECT * FROM ( 
            (SELECT 
                ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK, 
                CON.CONPERNATJUR, 
                CON.CONINFORMACION 
            FROM PRDCCION.EE_CONTACTO CON 
            WHERE CONFORMACONTACTO = 'EMA' 
                AND CONESTADO = 'ACT' 
                AND CPCTIPOGESTIONADO = 'CLIE' 
                AND CONCONTACTOCONFIRMADO = '1' 
            )
          ) WHERE RNK=1)EMA 
    ON EMA.CONPERNATJUR = TER.TERUUID 
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
    LEFT JOIN
        (SELECT 
            MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
            ,LOO.LOOOBLIGACION UUID_OBLIGACION
        FROM PRDCCION.CO_LOGOPERACION LOO
        WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
            -- Aplicación Pago, Aplicación Otras Fuentes
        GROUP BY
            LOO.LOOOBLIGACION
        ) FUP ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
--------------------------------------------------------------------------------
                    
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
        
    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('461361')
        AND PFI.PFICODIGO IN ('BMLI','BMMO') -- Bajo Monto Libre Inversión, Bajo Monto Motos
		AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (
                ((OBL.OBLESTOBLIG = '03' ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2) -- ## Mayor al 01 del mes anterior
                        ) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('CPEA','6002','CPNE','6004','CPNEJP','CPNENE','CREDIACCES','6007','6014','CREDLIBRAN','PP','6005','0007','0013') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- 01 Del mes Anterior y 01 Del mes Actual
                            ) 
                            AND TIOBL.TINCODIGO IN ('CPEA','6002','CPNE','6004','CPNEJP','CPNENE','CREDIACCES','6007','6014','CREDLIBRAN','PP','6005','0007','0013')
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))       
            )
--------------------------------------------------------------------------------
) WHERE 1=1 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_BM DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_BM DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_BM DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)


	
	
-- 2_consumo_DC
-- ## INFORMACION DE CONSUMO PARA REPORTAR A DATACREDITO
--/ Genera la informacion para reportar a Datacredito de los productos de Consumo /
SELECT 
TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,
    ULT_CUOTA
    FROM
(SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,
    CCFVALOR,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA,
    
-----------------
CASE
WHEN TIPO_DEUDOR = 'CO' AND CREDITO IN ('999') THEN 1
ELSE 0 END AS EXCLUSION

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
    'Consumo' TIPO_ARCHIVO,
    ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
    SYSDATE AS FECHA_REPORTE,
    PFI.PFICODIGO AS COD_PRODUCTO,
    PFI.PFIDESCRIPTION AS PRODUCTO,
    NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
    NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
    EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
    OBL.OBLNROOBLIGACION AS CREDITO,
    OBL.OBLFCHAINICIO AS FECHA_INICIO,
    OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
    OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
    CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
    NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
    NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
    EO.ESODESCRIPCION AS ESTADO,
    SEO.SEODESCRIPTION AS SUBESTADO,
    CASE
        WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
        THEN '1'
        WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
        THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- PPT
            THEN '6'            
--------------------------------------------------------------------------------
        ELSE 'X'
    END AS TIPO_IDENT,
    TER.PERID AS CEDULA,
    UPPER(
        TRANSLATE(
            REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
        ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
         ) AS NOMBRE,
    TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
    CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
    ELSE OBL.OBLVALORCUOTA
    END AS VALORCUOTA,
        CASE
            WHEN PFI.PFICODIGO IN ('SUMTO') AND NVL(SOD.SODDIASMORA,0)>539  THEN 539-- MORA SUMOTO
            ELSE NVL(SOD.SODDIASMORA,0)
        END AS DIASMORA,    
    OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
    SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
    NVL(SOD.SODVALORMORA,0) AS VALORMORA,
    OBL.OBLDIACORTE AS DIACORTE,
    NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
    NVL(
        TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,' ') AS CIUDADCORR,
    NVL(
        TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,' ') AS DEPARTAMENTOCORR,
    NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
    NVL(TER.TERTELEFONO,' ') AS TELEFONO,
    COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
    LOWER(COALESCE (EMA.CONINFORMACION,
    TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
    SUBSTR(
    TRANSLATE(
        TRIM(REGEXP_REPLACE(REPLACE(
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                DIR.CONINFORMACION,
                                TER.TERDIRECCION,'0'))
            ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
            ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
            ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
        ,',',', '), '[^A-Za-z0-1ÁÉÍÓÚáéíóú ]', ''))
    ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
    ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
    ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
        AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /* 'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                    'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                    'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
------------ FILTRO FECHA EJECUCION MAYOR O IGUAL AL 01 DEL MES ANTERIOR -------
--ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2) -- ## Mayor o igual al 01 del mes anterior
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
        (SELECT * FROM (
            (SELECT
                ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                CON.CONPERNATJUR,
                CON.CONINFORMACION
            FROM PRDCCION.EE_CONTACTO CON
            WHERE CONFORMACONTACTO = 'DIR'
                AND CONESTADO = 'ACT'
                AND CPCTIPOGESTIONADO = 'CLIE'
                AND CONAPLICACORRESPONDENCIA = '1'
            )
        ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
            ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
        (SELECT * FROM (
            (SELECT
                ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                CON.CONPERNATJUR,
                CON.CONINFORMACION
            FROM PRDCCION.EE_CONTACTO CON
            WHERE CONFORMACONTACTO = 'EMA'
                AND CONESTADO = 'ACT'
                AND CPCTIPOGESTIONADO = 'CLIE'
                AND CONCONTACTOCONFIRMADO = '1'
            )
        ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE',
						'CEMCCIM',
'CEMMCIM',
'CERCCIM',
'CERESMICRO',
'CERMCIM',
'SUMOCO',
'SUMOORI',
'SUMOTU'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-2)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-2)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------
    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
        AND OBL.OBLNROOBLIGACION NOT IN ('2032786')
        AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR', 'CLITE', 'CLITP','UBCL','UBCLP')-- Bajo Monto Libre Inversión, Bajo Monto Motos
		AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' and SOD.SODTIPONEGOCIO IN ('0009','CPEA','6002','CPNE','6004','CPNEJP','CPNENE','CREDIACCES','6007','6014','CREDLIBRAN','PP','6005','0007','0013','CSMCA','CSMCA2','CSMNCA','CSMNCA2')) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                       and TIOBL.TINCODIGO IN ('0009','CPEA','6002','CPNE','6004','CPNEJP','CPNENE','CREDIACCES','6007','6014','CREDLIBRAN','PP','6005','0007','0013','CSMCA','CSMCA2','CSMNCA','CSMNCA2') ) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('0009','CPEA','6002','CPNE','6004','CPNEJP','CPNENE','CREDIACCES','6007','6014','CREDLIBRAN','PP','6005','0007','0013','CSMCA','CSMCA2','CSMNCA','CSMNCA2') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                            ) 
                            AND TIOBL.TINCODIGO IN ('0009','CPEA','6002','CPNE','6004','CPNEJP','CPNENE','CREDIACCES','6007','6014','CREDLIBRAN','PP','6005','0007','0013','CSMCA','CSMCA2','CSMNCA','CSMNCA2') -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
)
WHERE EXCLUSION =0
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -2)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_CS DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.CREDITO IN('1246198') THEN LPAD('01',2,'0') ---- PQR BORRAR LUEGO
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.CREDITO IN('1246198') THEN LPAD('01',2,'0') --PQR BORRAR
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-2)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.CREDITO IN('1246198') THEN LPAD('0',3,'0') ---- PQR BORRAR
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.CREDITO IN('1246198') THEN LPAD('0',11,'0') --- PQR BORRAR
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.CREDITO IN('1246198') THEN LPAD('0',3,'0') --- PQR BORRAR
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_CS DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_CS DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)

-- reporte2
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -2)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_CS DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.CREDITO IN('1246198') THEN LPAD('01',2,'0') ---- PQR BORRAR LUEGO
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.CREDITO IN('1246198') THEN LPAD('01',2,'0') --PQR BORRAR
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-2)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.CREDITO IN('1246198') THEN LPAD('0',3,'0') ---- PQR BORRAR
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.CREDITO IN('1246198') THEN LPAD('0',11,'0') --- PQR BORRAR
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.CREDITO IN('1246198') THEN LPAD('0',3,'0') --- PQR BORRAR
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_CS DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_CS DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 3_microcredito_DC
-- ## INFORMACION DE MICROCREDITO PARA REPORTAR A DATACREDITO
--/ Genera la informacion para reportar a Datacredito de los productos de Microcredito /
SELECT 
TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,
    ULT_CUOTA
    FROM
(SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA,
    
-----------------
CASE
WHEN TIPO_DEUDOR = 'CO' AND CREDITO IN ('999') THEN 1
ELSE 0 END AS EXCLUSION
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Microcredito' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE 
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'         
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
             ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION, 
              TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
        TRANSLATE(
            TRIM(REGEXP_REPLACE(REPLACE(
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                    DIR.CONINFORMACION, 
                                    TER.TERDIRECCION,'0'))
                ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),'  ',' ')
            ,',',', '), '[^A-Za-z0-0ÁÉÍÓÚáéíóú ]', ''))
        ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
    ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
                (
                    SELECT OBL.OBLNROOBLIGACION AS CREDITO
                        ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                        ,LG.LOOFECHAOPERACION FECHA_INGRESO
                        ,LG.LOOFECHASISTEMA FECHA_APL
                        ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                    FROM PRDCCION.CO_OBLIGACION OBL
                        INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                        INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                        INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                    WHERE LG.LOOREVERSADO = 0
                        AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                        AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                        /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                            'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                            'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                        */
                )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
------------ FILTRO FECHA EJECUCION MAYOR O IGUAL AL 01 DEL MES ANTERIOR -------
 --ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor o igual al 01 del mes anterior
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE',
						'CEMCCIM',
'CEMMCIM',
'CERCCIM',
'CERESMICRO',
'CERMCIM',
'SUMOCO',
'SUMOORI',
'SUMOTU'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
        AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','12','CAU','ACCES','11','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
		AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (
                ((OBL.OBLESTOBLIG = '03' ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2) -- ## Mayor al 01 del mes anterior
                        ) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('0010','0006','6006','6003','0008','0013') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-2) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)  -- 01 Del mes Anterior y 01 Del mes Actual
                            ) 
                            AND TIOBL.TINCODIGO IN ('0010','0006','6006','6003','0008','0013')
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                
                    )
            AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- 01 Del mes Actual
                OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('6003','0013') OR SOD.SODTIPONEGOCIO IN ('6003'))
            
            )
--------------------------------------------------------------------------------
) WHERE 1=1
)
WHERE EXCLUSION =0
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_MC DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_MC DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_MC DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 4_moviaval_DC
-- ## INFORMACION DE MOVIAVAL PARA REPORTAR A DATACREDITO
--/ Genera la informacion para reportar a Datacredito de los productos de Moviaval /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Moviaval' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'       
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        CASE
            WHEN CIUCORRESP.CIUCODIGO = '99990' THEN '05001' -- 99990 -> Caracas
            ELSE NVL(CIUCORRESP.CIUCODIGO,0) 
        END AS COD_CIUDADCORR,
        CASE
            WHEN CIUCORRESP.CIUNOMBRE = 'Caracas' THEN 'Medellin'
            ELSE 
                NVL(
                    TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
                ,' ') 
            END AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','CEMCCIM',
'CEMMCIM', 'CERCCIM',
'CERESMICRO',
'CERMCIM')
                    /* 'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                       'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                       'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
        ) FUP ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------
    WHERE 1=1 ---AND OBL.OBLNROOBLIGACION IN ('1328835')
        AND OBL.OBLDUENO NOT IN ('4E26590427FC4CBE56AC1A060C447565','96D583B1BC24EB0B97AC1A600A447565')
		AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (
                ((OBL.OBLESTOBLIG = '03' )
                    OR (OBL.OBLESTOBLIG = '04'
                    AND FUP.FECHA_ULTIMOPAGO -- OBL.OBLFECHACANCELACION
                    >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                    ) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('CEMOVI','CERESFI','CEMCCIM','CEMMCIM', 'CERCCIM','CERESMICRO','CERMCIM','6013','6012') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- 01 Del mes Anterior y 01 Del mes Actual
                            ) 
                            AND OBL.OBLESTOBLIG = '04' AND TIOBL.TINCODIGO IN ('CEMOVI','CERESFI','CEMCCIM','CEMMCIM', 'CERCCIM','CERESMICRO','CERMCIM','6013','6012')
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
            )
--------------------------------------------------------------------------------
) WHERE 1=1
ORDER BY CREDITO

-- reporte

------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)

-- reporte2
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)
	
-- reporte3 CIF
------------------------- MAESTRO MOVIAVAL CIFIN TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO E CONTROL
SELECT DISTINCT
	LPAD(1,1,0)|| --Tipo registro
	LPAD(12,2,0)|| --Codigo paquete
	'150'|| --tipo de entidad
	'190'|| --- codigo de entidad
	LPAD(' ',10,' ')|| --- reservado
	LPAD(1,2,0)||--Tipo de reporte
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
	
	AS REGISTRO_CONTROL
	
FROM 
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO IN ('BMLI', 'BMMO')
----aqui empieza el reporte	
UNION
select
	LPAD(2,1,0)|| --Tipo registro
	CASE
            WHEN DC.TIPO_IDENT = '1' -- CC: Cédula de Ciudadanía
            THEN '01'
            WHEN DC.TIPO_IDENT = '2' -- NIT: NIT
            THEN '02'
            WHEN DC.TIPO_IDENT IN ('4') -- CE: Cédula de extranjería
            THEN '03'
            WHEN DC.TIPO_IDENT IN ('7') -- TI: Tarjeta de identidad
            THEN '04'
            WHEN DC.TIPO_IDENT IN ('5') -- PASA: Pasaporte
            THEN '05'
            WHEN DC.TIPO_IDENT IN ('6') -- ppt
            THEN '13'       
            ELSE '00'
	END || --TIPO DE IDENTIFICACION
	LPAD(DC.CEDULA,15,'0') || -- NUMERO DE IDENTIFICACION
	RPAD(UPPER(DC.NOMBRE),60,' ') || -- NOMBRE COMPLETO (MAYÚS)
	LPAD(' ',2,' ')||--reservado
	TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA LIMITE DE PAGO
	LPAD(' ',2,' ')|| --ESPACIOS DEL NUMERO DEL CREDITO
 --   LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
  CASE 
    WHEN tmp.credito is not null 
    then LPAD(DC.CREDITO,18,' ') 
    else  LPAD(DC.CREDITO,18,'0') 
  END ||
	LPAD(1,6,0)|| ---sucursal
	CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('P',1,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('S',1,'0') 
        ELSE '0'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR
	LPAD(' ',2,' ') ||-- CALIFICACION
	LPAD(' ',2,' ') ||-- SITUACION
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('07',2,'0')
        ELSE LPAD('04',2,'0')
    END 
    || -- ESTADO DE LA CUENTA
    CASE
        WHEN DC.DIASMORA < 30 THEN LPAD('00',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('01',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('02',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('03',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA < 150 THEN LPAD('04',2,'0') 
        WHEN DC.DIASMORA < 180 THEN LPAD('05',2,'0') 
        WHEN DC.DIASMORA < 210 THEN LPAD('06',2,'0') 
        WHEN DC.DIASMORA < 240 THEN LPAD('07',2,'0') 
        WHEN DC.DIASMORA < 270 THEN LPAD('08',2,'0') 
        WHEN DC.DIASMORA < 300 THEN LPAD('09',2,'0') 
        WHEN DC.DIASMORA < 330 THEN LPAD('10',2,'0') 
        WHEN DC.DIASMORA < 360 THEN LPAD('11',2,'0') 
        WHEN DC.DIASMORA < 540 THEN LPAD('12',2,'0') 
        WHEN DC.DIASMORA < 730 THEN LPAD('13',2,'0') 
        WHEN DC.DIASMORA >= 730 THEN LPAD('14',2,'0') 		
    END 
    || -- edad de mora
	LPAD(' ',2,' ')||-- ANOS MORA OPCIONAL
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD')|| -- FECHA CORTE
	TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
	LPAD(' ',8,' ')|| --- FECHA TERMINACION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA EXIGIBILIDAD OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA PRESCRIPCION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA DE PAGO OPCIONAL
	LPAD(' ',2,' ')|| --- MODO EXTINCION OPCIONAL
	LPAD(' ',2,' ')|| --- TIPO DE PAGO OPCIONAL
	LPAD('05',2,'0') || -- PERIODICIDAD DE PAGO (Mensual)
	LPAD(' ',3,' ')|| --- PROBABILIDAD
	LPAD(' ',3,' ')|| --- CUOTAS PAGADAS
	LPAD(' ',3,' ')|| --- CUOTAS PACTADAS
	CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    ||  --- CUOTAS EN MORA
	LPAD(CAST(DC.VLRDESEMBOLSO/1000 AS INT),12,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',12,'0')
        
        ELSE LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') 
    END
    || -- VALOR MORA (VALOR MORA)	
    LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') || -- VALOR DEL SALDO
    LPAD(CAST(DC.VALORCUOTA/1000 AS INT),12,'0') || -- VALOR CUOTA MENSUAL
	LPAD(' ',12,' ') || -- VALOR CARGO FIJO
	LPAD('033',3,'0') || -- LINEA DE CREDITO
	LPAD(' ',3,' ') || -- CLAUSULA DE PERMANENCIA
	LPAD('1',3,'0') || -- TIPO DE CONTRATO (CREDITO)
	LPAD(' ',3,' ') || -- ESTADO DE CONTRATO
	LPAD(' ',2,' ') || -- TERMINO DE VIGENCIA DE CONTRATO
	LPAD(' ',3,' ') || -- NUMERO MESES CONTRATO
	LPAD(' ',3,' ') || -- NATURALEZA JURIDICA
	LPAD(' ',2,' ') || -- MODALIDAD DE CREDITO
	LPAD(' ',2,' ') || -- TIPO MONEDA
	LPAD(' ',2,' ') || -- TIPO DE GARANTIA
	LPAD(' ',12,' ') || -- VALOR GARANTIA
	LPAD('02',2,'0') || -- OBLIGACION REESTRUCTURADA
	LPAD(' ',2,' ') || -- NATURALEZA
	LPAD(' ',3,' ') || -- NUMERO DE REESTRUCTURACIONES
	LPAD(' ',2,' ') || -- CLASE DE TARJETA
	LPAD(' ',4,' ') || -- NUMERO DE CHEQUES DEVUELTOS
	LPAD(' ',2,' ') || -- CATEGORIA SERVICIOS
	LPAD(' ',2,' ') || -- PLAZO
	LPAD(' ',6,' ') || -- DIAS CARTERA
	LPAD(' ',2,' ') || -- TIPO DE CUENTA
	LPAD(' ',12,' ') || -- CUPO SOBREGIRO
	LPAD(' ',3,' ') || -- DIAS AUTORIZADOS
	RPAD(DC.DIRECCION,60,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDAD CASA
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',60,' ') || -- EMPRESA
	LPAD(' ',60,' ') || -- DIRECCION
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDADD (9)
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',8,' ') || -- FECHA INCIO
	LPAD(' ',8,' ') || -- FECHA TERMINACION
	LPAD(' ',2,' ') || -- NUM RENOV CDT
	LPAD(' ',2,' ') || -- CTA
	LPAD(' ',2,' ') || -- TIPO IDENTI ORD
	LPAD(' ',14,' ') || -- NUM IDENT ORIGINARIA
	LPAD(' ',3,' ') || -- TIPO ENTIDAD ORIG
	LPAD(' ',3,' ') || -- COD ENT ORIGINARIA
	LPAD(' ',2,' ') || -- TIPO FIDEICOMISO
	LPAD(' ',12,' ') || -- NUM FIDEICOMISO
	LPAD(' ',60,' ') || -- NOMBRE FIDEICOMISO
	LPAD(' ',4,' ') || -- TIPO DEUDA CARTERA
	LPAD(' ',4,' ') || -- TIPO POLIZA
	LPAD(' ',6,' ') || -- CODIGO RAMO
	LPAD(' ',20,' ') || -- NUM REAL Tarjeta
	RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO
	RPAD(DC.MOVIL,60,' ') || -- CELULAR
	LPAD(' ',12,' ')  -- VALOR REAL PAGADO
FROM
    ACT_ESTRUCTURA_MA DC
    LEFT JOIN ACTUARIA.TEMP_CREDITOS_CONESPACIOS@DBLINKACTUARIA tmp on tmp.credito = dc.credito
WHERE COD_PRODUCTO IN ('BMLI', 'BMMO')
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO - PIE DE PAGINA
SELECT
    LPAD('9',1,'0') || -- TIPO REGISTRO
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS CON ENCABEZADO Y PIE DE PAGINA
    LPAD(COUNT(DC.CREDITO),8,'0') || -- NUMERO DE REGISTROS
	LPAD('0',8,'0') || -- NUMERO DE REGISTROS TIPO 3
	LPAD('0',8,'0')  -- NUMERO DE REGISTROS TIPO 4
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO IN ('BMLI', 'BMMO')
) 
MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN '1' THEN 1
        WHEN '9' THEN 3
        ELSE 2
        END

-- reporte4 CIF
------------------------- MAESTRO MOVIAVAL CIFIN TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO E CONTROL
SELECT DISTINCT
	LPAD(1,1,0)|| --Tipo registro
	LPAD(12,2,0)|| --Codigo paquete
	'150'|| --tipo de entidad
	'190'|| --- codigo de entidad
	LPAD(' ',10,' ')|| --- reservado
	LPAD(1,2,0)||--Tipo de reporte
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
	
	AS REGISTRO_CONTROL
	
FROM 
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
----aqui empieza el reporte	
UNION
select
	LPAD(2,1,0)|| --Tipo registro
	CASE
            WHEN DC.TIPO_IDENT = '1' -- CC: Cédula de Ciudadanía
            THEN '01'
            WHEN DC.TIPO_IDENT = '2' -- NIT: NIT
            THEN '02'
            WHEN DC.TIPO_IDENT IN ('4') -- CE: Cédula de extranjería
            THEN '03'
            WHEN DC.TIPO_IDENT IN ('7') -- TI: Tarjeta de identidad
            THEN '04'
            WHEN DC.TIPO_IDENT IN ('5') -- PASA: Pasaporte
            THEN '05'
            WHEN DC.TIPO_IDENT IN ('6') -- ppt
            THEN '13'       
            ELSE '00'
	END || --TIPO DE IDENTIFICACION
	LPAD(DC.CEDULA,15,'0') || -- NUMERO DE IDENTIFICACION
	RPAD(UPPER(DC.NOMBRE),60,' ') || -- NOMBRE COMPLETO (MAYÚS)
	LPAD(' ',2,' ')||--reservado
	TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA LIMITE DE PAGO
	LPAD(' ',2,' ')|| --ESPACIOS DEL NUMERO DEL CREDITO
 --   LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
  CASE 
    WHEN tmp.credito is not null 
    then LPAD(DC.CREDITO,18,' ') 
    else  LPAD(DC.CREDITO,18,'0') 
  END ||
	LPAD(1,6,0)|| ---sucursal
	CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('P',1,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('S',1,'0') 
        ELSE '0'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR
	LPAD(' ',2,' ') ||-- CALIFICACION
	LPAD(' ',2,' ') ||-- SITUACION
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('07',2,'0')
        ELSE LPAD('04',2,'0')
    END 
    || -- ESTADO DE LA CUENTA
    CASE
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS - Se ajusta a que siempre este en mora
        WHEN DC.DIASMORA < 60 THEN LPAD('01',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('02',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('03',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA < 150 THEN LPAD('04',2,'0') 
        WHEN DC.DIASMORA < 180 THEN LPAD('05',2,'0') 
        WHEN DC.DIASMORA < 210 THEN LPAD('06',2,'0') 
        WHEN DC.DIASMORA < 240 THEN LPAD('07',2,'0') 
        WHEN DC.DIASMORA < 270 THEN LPAD('08',2,'0') 
        WHEN DC.DIASMORA < 300 THEN LPAD('09',2,'0') 
        WHEN DC.DIASMORA < 330 THEN LPAD('10',2,'0') 
        WHEN DC.DIASMORA < 360 THEN LPAD('11',2,'0') 
        WHEN DC.DIASMORA < 540 THEN LPAD('12',2,'0') 
        WHEN DC.DIASMORA < 730 THEN LPAD('13',2,'0') 
        WHEN DC.DIASMORA >= 730 THEN LPAD('14',2,'0') 		
    END 
    || -- edad de mora
	LPAD(' ',2,' ')||-- ANOS MORA OPCIONAL
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD')|| -- FECHA CORTE
	TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
	LPAD(' ',8,' ')|| --- FECHA TERMINACION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA EXIGIBILIDAD OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA PRESCRIPCION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA DE PAGO OPCIONAL
	LPAD(' ',2,' ')|| --- MODO EXTINCION OPCIONAL
	LPAD(' ',2,' ')|| --- TIPO DE PAGO OPCIONAL
	LPAD('05',2,'0') || -- PERIODICIDAD DE PAGO (Mensual)
	LPAD(' ',3,' ')|| --- PROBABILIDAD
	LPAD(' ',3,' ')|| --- CUOTAS PAGADAS
	LPAD(' ',3,' ')|| --- CUOTAS PACTADAS
	CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        
        ELSE LPAD(DC.CUOTAS,3,'0')
    END
    ||  --- CUOTAS EN MORA
	LPAD(CAST(DC.VLRDESEMBOLSO/1000 AS INT),12,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',12,'0')
        
        ELSE LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') 
    END
    || -- VALOR MORA (VALOR MORA)	
    LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') || -- VALOR DEL SALDO
    LPAD(CAST(DC.VALORCUOTA/1000 AS INT),12,'0') || -- VALOR CUOTA MENSUAL
	LPAD(' ',12,' ') || -- VALOR CARGO FIJO
	LPAD('033',3,'0') || -- LINEA DE CREDITO
	LPAD(' ',3,' ') || -- CLAUSULA DE PERMANENCIA
	LPAD('1',3,'0') || -- TIPO DE CONTRATO (CREDITO)
	LPAD(' ',3,' ') || -- ESTADO DE CONTRATO
	LPAD(' ',2,' ') || -- TERMINO DE VIGENCIA DE CONTRATO
	LPAD(' ',3,' ') || -- NUMERO MESES CONTRATO
	LPAD(' ',3,' ') || -- NATURALEZA JURIDICA
	LPAD(' ',2,' ') || -- MODALIDAD DE CREDITO
	LPAD(' ',2,' ') || -- TIPO MONEDA
	LPAD(' ',2,' ') || -- TIPO DE GARANTIA
	LPAD(' ',12,' ') || -- VALOR GARANTIA
	LPAD('02',2,'0') || -- OBLIGACION REESTRUCTURADA
	LPAD(' ',2,' ') || -- NATURALEZA
	LPAD(' ',3,' ') || -- NUMERO DE REESTRUCTURACIONES
	LPAD(' ',2,' ') || -- CLASE DE TARJETA
	LPAD(' ',4,' ') || -- NUMERO DE CHEQUES DEVUELTOS
	LPAD(' ',2,' ') || -- CATEGORIA SERVICIOS
	LPAD(' ',2,' ') || -- PLAZO
	LPAD(' ',6,' ') || -- DIAS CARTERA
	LPAD(' ',2,' ') || -- TIPO DE CUENTA
	LPAD(' ',12,' ') || -- CUPO SOBREGIRO
	LPAD(' ',3,' ') || -- DIAS AUTORIZADOS
	RPAD(DC.DIRECCION,60,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDAD CASA
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',60,' ') || -- EMPRESA
	LPAD(' ',60,' ') || -- DIRECCION
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDADD (9)
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',8,' ') || -- FECHA INCIO
	LPAD(' ',8,' ') || -- FECHA TERMINACION
	LPAD(' ',2,' ') || -- NUM RENOV CDT
	LPAD(' ',2,' ') || -- CTA
	LPAD(' ',2,' ') || -- TIPO IDENTI ORD
	LPAD(' ',14,' ') || -- NUM IDENT ORIGINARIA
	LPAD(' ',3,' ') || -- TIPO ENTIDAD ORIG
	LPAD(' ',3,' ') || -- COD ENT ORIGINARIA
	LPAD(' ',2,' ') || -- TIPO FIDEICOMISO
	LPAD(' ',12,' ') || -- NUM FIDEICOMISO
	LPAD(' ',60,' ') || -- NOMBRE FIDEICOMISO
	LPAD(' ',4,' ') || -- TIPO DEUDA CARTERA
	LPAD(' ',4,' ') || -- TIPO POLIZA
	LPAD(' ',6,' ') || -- CODIGO RAMO
	LPAD(' ',20,' ') || -- NUM REAL Tarjeta
	RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO
	RPAD(DC.MOVIL,60,' ') || -- CELULAR
	LPAD(' ',12,' ')  -- VALOR REAL PAGADO
FROM
    ACT_ESTRUCTURA_MA DC
    LEFT JOIN ACTUARIA.TEMP_CREDITOS_CONESPACIOS@DBLINKACTUARIA tmp on tmp.credito = dc.credito
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO - PIE DE PAGINA
SELECT
    LPAD('9',1,'0') || -- TIPO REGISTRO
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS CON ENCABEZADO Y PIE DE PAGINA
    LPAD(COUNT(DC.CREDITO),8,'0') || -- NUMERO DE REGISTROS
	LPAD('0',8,'0') || -- NUMERO DE REGISTROS TIPO 3
	LPAD('0',8,'0')  -- NUMERO DE REGISTROS TIPO 4
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_MA DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
) 
MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN '1' THEN 1
        WHEN '9' THEN 3
        ELSE 2
        END


-- 5_resfin_DC
-- ## INFORMACION DE RESFIN PARA REPORTAR A DATACREDITO
--/ Genera la informacion para reportar a Datacredito de los productos de Resfin /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,
	
--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Resfin' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
             WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                  
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
                (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','CEMCCIM',
'CEMMCIM', 'CERCCIM',
'CERESMICRO',
'CERMCIM')
                    /* 'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                    'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                    'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
                )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 ---AND OBL.OBLNROOBLIGACION IN ('1328835')
	    AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (
                ((OBL.OBLESTOBLIG = '03' )
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        ) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
            AND 
                ((SOD.SODTIPONEGOCIO IN ('CERESFI','CERESMICRO','CERMCIM','CERCCIM') 
                    OR ((
                            FUP.FECHA_ULTIMOPAGO BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- 01 Del mes Anterior y 01 Del mes Actual
                        ) 
                        AND OBL.OBLESTOBLIG = '04' AND TIOBL.TINCODIGO IN ('CERESFI','CERESMICRO','CERMCIM','CERCCIM')

                        )
                    )
                /*
                Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                */
                )
            )
--------------------------------------------------------------------------------
) WHERE 1=1
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)
	
-- reporte2
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)
	
-- reporte3 CIF
------------------------- MAESTRO RESFIN CIFIN TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO E CONTROL
SELECT DISTINCT
	LPAD(1,1,0)|| --Tipo registro
	LPAD(12,2,0)|| --Codigo paquete
	'150'|| --tipo de entidad
	'192'|| --- codigo de entidad
	LPAD(' ',10,' ')|| --- reservado
	LPAD(1,2,0)||--Tipo de reporte
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
	
	AS REGISTRO_CONTROL
	
FROM 
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
----aqui empieza el reporte	
UNION
select
	LPAD(2,1,0)|| --Tipo registro
	CASE
            WHEN DC.TIPO_IDENT = '1' -- CC: Cédula de Ciudadanía
            THEN '01'
            WHEN DC.TIPO_IDENT = '2' -- NIT: NIT
            THEN '02'
            WHEN DC.TIPO_IDENT IN ('4') -- CE: Cédula de extranjería
            THEN '03'
            WHEN DC.TIPO_IDENT IN ('7') -- TI: Tarjeta de identidad
            THEN '04'
            WHEN DC.TIPO_IDENT IN ('5') -- PASA: Pasaporte
            THEN '05'
            WHEN DC.TIPO_IDENT IN ('6') -- ppt
            THEN '13'       
            ELSE '00'
	END || --TIPO DE IDENTIFICACION
	LPAD(DC.CEDULA,15,'0') || -- NUMERO DE IDENTIFICACION
	RPAD(UPPER(DC.NOMBRE),60,' ') || -- NOMBRE COMPLETO (MAYÚS)
	LPAD(' ',2,' ')||--reservado
	TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA LIMITE DE PAGO
	LPAD(' ',2,' ')|| --ESPACIOS DEL NUMERO DEL CREDITO
 --   LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
  CASE 
    WHEN tmp.credito is not null 
    then LPAD(DC.CREDITO,18,' ') 
    else  LPAD(DC.CREDITO,18,'0') 
  END ||
	LPAD(1,6,0)|| ---sucursal
	CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('P',1,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('S',1,'0') 
        ELSE '0'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR
	LPAD(' ',2,' ') ||-- CALIFICACION
	LPAD(' ',2,' ') ||-- SITUACION
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('07',2,'0')
        ELSE LPAD('04',2,'0')
    END 
    || -- ESTADO DE LA CUENTA
    CASE
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS - se ajusta a que siempre este en mora
        WHEN DC.DIASMORA < 60 THEN LPAD('01',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('02',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('03',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA < 150 THEN LPAD('04',2,'0') 
        WHEN DC.DIASMORA < 180 THEN LPAD('05',2,'0') 
        WHEN DC.DIASMORA < 210 THEN LPAD('06',2,'0') 
        WHEN DC.DIASMORA < 240 THEN LPAD('07',2,'0') 
        WHEN DC.DIASMORA < 270 THEN LPAD('08',2,'0') 
        WHEN DC.DIASMORA < 300 THEN LPAD('09',2,'0') 
        WHEN DC.DIASMORA < 330 THEN LPAD('10',2,'0') 
        WHEN DC.DIASMORA < 360 THEN LPAD('11',2,'0') 
        WHEN DC.DIASMORA < 540 THEN LPAD('12',2,'0') 
        WHEN DC.DIASMORA < 730 THEN LPAD('13',2,'0') 
        WHEN DC.DIASMORA >= 730 THEN LPAD('14',2,'0') 		
    END 
    || -- edad de mora
	LPAD(' ',2,' ')||-- ANOS MORA OPCIONAL
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD')|| -- FECHA CORTE
	TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
	LPAD(' ',8,' ')|| --- FECHA TERMINACION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA EXIGIBILIDAD OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA PRESCRIPCION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA DE PAGO OPCIONAL
	LPAD(' ',2,' ')|| --- MODO EXTINCION OPCIONAL
	LPAD(' ',2,' ')|| --- TIPO DE PAGO OPCIONAL
	LPAD('05',2,'0') || -- PERIODICIDAD DE PAGO (Mensual)
	LPAD(' ',3,' ')|| --- PROBABILIDAD
	LPAD(' ',3,' ')|| --- CUOTAS PAGADAS
	LPAD(' ',3,' ')|| --- CUOTAS PACTADAS
	CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        
        ELSE LPAD(DC.CUOTAS,3,'0')
    END
    ||  --- CUOTAS EN MORA
	LPAD(CAST(DC.VLRDESEMBOLSO/1000 AS INT),12,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',12,'0')
        
        ELSE LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') 
    END
    || -- VALOR MORA (VALOR MORA)	
    LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') || -- VALOR DEL SALDO
    LPAD(CAST(DC.VALORCUOTA/1000 AS INT),12,'0') || -- VALOR CUOTA MENSUAL
	LPAD(' ',12,' ') || -- VALOR CARGO FIJO
	LPAD('033',3,'0') || -- LINEA DE CREDITO
	LPAD(' ',3,' ') || -- CLAUSULA DE PERMANENCIA
	LPAD('1',3,'0') || -- TIPO DE CONTRATO (CREDITO)
	LPAD(' ',3,' ') || -- ESTADO DE CONTRATO
	LPAD(' ',2,' ') || -- TERMINO DE VIGENCIA DE CONTRATO
	LPAD(' ',3,' ') || -- NUMERO MESES CONTRATO
	LPAD(' ',3,' ') || -- NATURALEZA JURIDICA
	LPAD(' ',2,' ') || -- MODALIDAD DE CREDITO
	LPAD(' ',2,' ') || -- TIPO MONEDA
	LPAD(' ',2,' ') || -- TIPO DE GARANTIA
	LPAD(' ',12,' ') || -- VALOR GARANTIA
	LPAD('02',2,'0') || -- OBLIGACION REESTRUCTURADA
	LPAD(' ',2,' ') || -- NATURALEZA
	LPAD(' ',3,' ') || -- NUMERO DE REESTRUCTURACIONES
	LPAD(' ',2,' ') || -- CLASE DE TARJETA
	LPAD(' ',4,' ') || -- NUMERO DE CHEQUES DEVUELTOS
	LPAD(' ',2,' ') || -- CATEGORIA SERVICIOS
	LPAD(' ',2,' ') || -- PLAZO
	LPAD(' ',6,' ') || -- DIAS CARTERA
	LPAD(' ',2,' ') || -- TIPO DE CUENTA
	LPAD(' ',12,' ') || -- CUPO SOBREGIRO
	LPAD(' ',3,' ') || -- DIAS AUTORIZADOS
	RPAD(DC.DIRECCION,60,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDAD CASA
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',60,' ') || -- EMPRESA
	LPAD(' ',60,' ') || -- DIRECCION
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDADD (9)
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',8,' ') || -- FECHA INCIO
	LPAD(' ',8,' ') || -- FECHA TERMINACION
	LPAD(' ',2,' ') || -- NUM RENOV CDT
	LPAD(' ',2,' ') || -- CTA
	LPAD(' ',2,' ') || -- TIPO IDENTI ORD
	LPAD(' ',14,' ') || -- NUM IDENT ORIGINARIA
	LPAD(' ',3,' ') || -- TIPO ENTIDAD ORIG
	LPAD(' ',3,' ') || -- COD ENT ORIGINARIA
	LPAD(' ',2,' ') || -- TIPO FIDEICOMISO
	LPAD(' ',12,' ') || -- NUM FIDEICOMISO
	LPAD(' ',60,' ') || -- NOMBRE FIDEICOMISO
	LPAD(' ',4,' ') || -- TIPO DEUDA CARTERA
	LPAD(' ',4,' ') || -- TIPO POLIZA
	LPAD(' ',6,' ') || -- CODIGO RAMO
	LPAD(' ',20,' ') || -- NUM REAL Tarjeta
	RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO
	RPAD(DC.MOVIL,60,' ') || -- CELULAR
	LPAD(' ',12,' ')  -- VALOR REAL PAGADO
FROM
    ACT_ESTRUCTURA_RF DC
    LEFT JOIN ACTUARIA.TEMP_CREDITOS_CONESPACIOS@DBLINKACTUARIA tmp on tmp.credito = dc.credito
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO - PIE DE PAGINA
SELECT
    LPAD('9',1,'0') || -- TIPO REGISTRO
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS CON ENCABEZADO Y PIE DE PAGINA
    LPAD(COUNT(DC.CREDITO),8,'0') || -- NUMERO DE REGISTROS
	LPAD('0',8,'0') || -- NUMERO DE REGISTROS TIPO 3
	LPAD('0',8,'0')  -- NUMERO DE REGISTROS TIPO 4
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
) 
MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN '1' THEN 1
        WHEN '9' THEN 3
        ELSE 2
        END
		
-- reporte4 CIF
------------------------- MAESTRO RESFIN CIFIN TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO E CONTROL
SELECT DISTINCT
	LPAD(1,1,0)|| --Tipo registro
	LPAD(12,2,0)|| --Codigo paquete
	'150'|| --tipo de entidad
	'192'|| --- codigo de entidad
	LPAD(' ',10,' ')|| --- reservado
	LPAD(1,2,0)||--Tipo de reporte
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
	
	AS REGISTRO_CONTROL
	
FROM 
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
----aqui empieza el reporte	
UNION
select
	LPAD(2,1,0)|| --Tipo registro
	CASE
            WHEN DC.TIPO_IDENT = '1' -- CC: Cédula de Ciudadanía
            THEN '01'
            WHEN DC.TIPO_IDENT = '2' -- NIT: NIT
            THEN '02'
            WHEN DC.TIPO_IDENT IN ('4') -- CE: Cédula de extranjería
            THEN '03'
            WHEN DC.TIPO_IDENT IN ('7') -- TI: Tarjeta de identidad
            THEN '04'
            WHEN DC.TIPO_IDENT IN ('5') -- PASA: Pasaporte
            THEN '05'
            WHEN DC.TIPO_IDENT IN ('6') -- ppt
            THEN '13'       
            ELSE '00'
	END || --TIPO DE IDENTIFICACION
	LPAD(DC.CEDULA,15,'0') || -- NUMERO DE IDENTIFICACION
	RPAD(UPPER(DC.NOMBRE),60,' ') || -- NOMBRE COMPLETO (MAYÚS)
	LPAD(' ',2,' ')||--reservado
	TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA LIMITE DE PAGO
	LPAD(' ',2,' ')|| --ESPACIOS DEL NUMERO DEL CREDITO
 --   LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
  CASE 
    WHEN tmp.credito is not null 
    then LPAD(DC.CREDITO,18,' ') 
    else  LPAD(DC.CREDITO,18,'0') 
  END ||
	LPAD(1,6,0)|| ---sucursal
	CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('P',1,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('S',1,'0') 
        ELSE '0'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR
	LPAD(' ',2,' ') ||-- CALIFICACION
	LPAD(' ',2,' ') ||-- SITUACION
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('07',2,'0')
        ELSE LPAD('04',2,'0')
    END 
    || -- ESTADO DE LA CUENTA
    CASE
        WHEN DC.DIASMORA < 30 THEN LPAD('00',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('01',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('02',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('03',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA < 150 THEN LPAD('04',2,'0') 
        WHEN DC.DIASMORA < 180 THEN LPAD('05',2,'0') 
        WHEN DC.DIASMORA < 210 THEN LPAD('06',2,'0') 
        WHEN DC.DIASMORA < 240 THEN LPAD('07',2,'0') 
        WHEN DC.DIASMORA < 270 THEN LPAD('08',2,'0') 
        WHEN DC.DIASMORA < 300 THEN LPAD('09',2,'0') 
        WHEN DC.DIASMORA < 330 THEN LPAD('10',2,'0') 
        WHEN DC.DIASMORA < 360 THEN LPAD('11',2,'0') 
        WHEN DC.DIASMORA < 540 THEN LPAD('12',2,'0') 
        WHEN DC.DIASMORA < 730 THEN LPAD('13',2,'0') 
        WHEN DC.DIASMORA >= 730 THEN LPAD('14',2,'0') 		
    END 
    || -- edad de mora
	LPAD(' ',2,' ')||-- ANOS MORA OPCIONAL
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD')|| -- FECHA CORTE
	TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
	LPAD(' ',8,' ')|| --- FECHA TERMINACION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA EXIGIBILIDAD OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA PRESCRIPCION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA DE PAGO OPCIONAL
	LPAD(' ',2,' ')|| --- MODO EXTINCION OPCIONAL
	LPAD(' ',2,' ')|| --- TIPO DE PAGO OPCIONAL
	LPAD('05',2,'0') || -- PERIODICIDAD DE PAGO (Mensual)
	LPAD(' ',3,' ')|| --- PROBABILIDAD
	LPAD(' ',3,' ')|| --- CUOTAS PAGADAS
	LPAD(' ',3,' ')|| --- CUOTAS PACTADAS
	CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    ||  --- CUOTAS EN MORA
	LPAD(CAST(DC.VLRDESEMBOLSO/1000 AS INT),12,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',12,'0')
        
        ELSE LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') 
    END
    || -- VALOR MORA (VALOR MORA)	
    LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') || -- VALOR DEL SALDO
    LPAD(CAST(DC.VALORCUOTA/1000 AS INT),12,'0') || -- VALOR CUOTA MENSUAL
	LPAD(' ',12,' ') || -- VALOR CARGO FIJO
	LPAD('033',3,'0') || -- LINEA DE CREDITO
	LPAD(' ',3,' ') || -- CLAUSULA DE PERMANENCIA
	LPAD('1',3,'0') || -- TIPO DE CONTRATO (CREDITO)
	LPAD(' ',3,' ') || -- ESTADO DE CONTRATO
	LPAD(' ',2,' ') || -- TERMINO DE VIGENCIA DE CONTRATO
	LPAD(' ',3,' ') || -- NUMERO MESES CONTRATO
	LPAD(' ',3,' ') || -- NATURALEZA JURIDICA
	LPAD(' ',2,' ') || -- MODALIDAD DE CREDITO
	LPAD(' ',2,' ') || -- TIPO MONEDA
	LPAD(' ',2,' ') || -- TIPO DE GARANTIA
	LPAD(' ',12,' ') || -- VALOR GARANTIA
	LPAD('02',2,'0') || -- OBLIGACION REESTRUCTURADA
	LPAD(' ',2,' ') || -- NATURALEZA
	LPAD(' ',3,' ') || -- NUMERO DE REESTRUCTURACIONES
	LPAD(' ',2,' ') || -- CLASE DE TARJETA
	LPAD(' ',4,' ') || -- NUMERO DE CHEQUES DEVUELTOS
	LPAD(' ',2,' ') || -- CATEGORIA SERVICIOS
	LPAD(' ',2,' ') || -- PLAZO
	LPAD(' ',6,' ') || -- DIAS CARTERA
	LPAD(' ',2,' ') || -- TIPO DE CUENTA
	LPAD(' ',12,' ') || -- CUPO SOBREGIRO
	LPAD(' ',3,' ') || -- DIAS AUTORIZADOS
	RPAD(DC.DIRECCION,60,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDAD CASA
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',60,' ') || -- EMPRESA
	LPAD(' ',60,' ') || -- DIRECCION
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDADD (9)
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',8,' ') || -- FECHA INCIO
	LPAD(' ',8,' ') || -- FECHA TERMINACION
	LPAD(' ',2,' ') || -- NUM RENOV CDT
	LPAD(' ',2,' ') || -- CTA
	LPAD(' ',2,' ') || -- TIPO IDENTI ORD
	LPAD(' ',14,' ') || -- NUM IDENT ORIGINARIA
	LPAD(' ',3,' ') || -- TIPO ENTIDAD ORIG
	LPAD(' ',3,' ') || -- COD ENT ORIGINARIA
	LPAD(' ',2,' ') || -- TIPO FIDEICOMISO
	LPAD(' ',12,' ') || -- NUM FIDEICOMISO
	LPAD(' ',60,' ') || -- NOMBRE FIDEICOMISO
	LPAD(' ',4,' ') || -- TIPO DEUDA CARTERA
	LPAD(' ',4,' ') || -- TIPO POLIZA
	LPAD(' ',6,' ') || -- CODIGO RAMO
	LPAD(' ',20,' ') || -- NUM REAL Tarjeta
	RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO
	RPAD(DC.MOVIL,60,' ') || -- CELULAR
	LPAD(' ',12,' ')  -- VALOR REAL PAGADO
FROM
    ACT_ESTRUCTURA_RF DC
    LEFT JOIN ACTUARIA.TEMP_CREDITOS_CONESPACIOS@DBLINKACTUARIA tmp on tmp.credito = dc.credito
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO - PIE DE PAGINA
SELECT
    LPAD('9',1,'0') || -- TIPO REGISTRO
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS CON ENCABEZADO Y PIE DE PAGINA
    LPAD(COUNT(DC.CREDITO),8,'0') || -- NUMERO DE REGISTROS
	LPAD('0',8,'0') || -- NUMERO DE REGISTROS TIPO 3
	LPAD('0',8,'0')  -- NUMERO DE REGISTROS TIPO 4
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_RF DC
WHERE COD_PRODUCTO  IN ('BMLI', 'BMMO')
) 
MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN '1' THEN 1
        WHEN '9' THEN 3
        ELSE 2
        END


-- 6_alquila_DC
-- ## INFORMACION DE ALQUILA PARA REPORTAR A DATACREDITO
/* Genera la informacion para reportar a Datacredito de los productos de Alquila */
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    nvl(ROUND(VLRDESEMBOLSO+TOTAL),VLRDESEMBOLSO)  AS VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
   -- VALORCUOTA,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Alquila' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
             WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '13'                  
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA,
        NVO.TOTAL AS TOTAL
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA =  ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Ultimo dia del mes anterior
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO AND TI.TENANT = SODTIN.TENANT
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO AND TIOBL.TENANT = OBL.TENANT
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO AND STN.TENANT = SOD.TENANT
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID AND OBL.TENANT = CFRO.TENANT
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO AND CFRO.TENANT = PFI.TENANT
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP 
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO 
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS 
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
                (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /* 'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                       'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                       'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
                )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                    (SELECT
                        ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                        CON.CONPERNATJUR,
                        CON.CONINFORMACION
                    FROM PRDCCION.EE_CONTACTO CON
                    WHERE CONFORMACONTACTO = 'DIR'
                        AND CONESTADO = 'ACT'
                        AND CPCTIPOGESTIONADO = 'CLIE'
                        AND CONAPLICACORRESPONDENCIA = '1'
                    )
                ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                    (SELECT
                        ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                        CON.CONPERNATJUR,
                        CON.CONINFORMACION
                    FROM PRDCCION.EE_CONTACTO CON
                    WHERE CONFORMACONTACTO = 'CEL'
                        AND CONESTADO = 'ACT'
                        AND CPCTIPOGESTIONADO = 'CLIE'
                        AND CONCONTACTOCONFIRMADO = '1'
                    )
                ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION AND OBL.TENANT = SOD.TENANT 
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                   -- AND OBL.OBLNROOBLIGACION = '1824432'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)) -- ## Ultimo dia del mes anterior
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
           -- AND OBL.OBLNROOBLIGACION = 1824432
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
        LEFT JOIN 
            (select 
                sum(LOOVALOROPERACION) AS TOTAL, LOOOBLIGACION
            from PRDCCION.CO_LOGOPERACION
            where 1 = 1 --LOOOBLIGACION = '781C5292E5933CBAFBAC1A608C4F626C'
                and LOOOPERREGLA =  '52EA787B104508A91DAC1C6C8E706572'
                and looreversado = 0
            group by LOOOBLIGACION
            )NVO ON NVO.LOOOBLIGACION = OBL.OBLUUID
            
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE  1 = 1 --OBL.OBLNROOBLIGACION IN ('1785234')
        AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP')-- Bajo Monto Libre Inversión, Bajo Monto Motos
		AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (
                ((OBL.OBLESTOBLIG = '03' ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        ) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND ((SOD.SODTIPONEGOCIO IN ('0015','0016' )  -- Alquiler Moto 2R, Alquiler Moto 2R No Causa
                    OR ((
                            FUP.FECHA_ULTIMOPAGO BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                        ) 
                        AND TIOBL.TINCODIGO IN ('0015','0016' )  -- Alquiler Moto 2R, Alquiler Moto 2R No Causa
                        )
                    )
                /*
                Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                */
                )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
--and credito = 1785234
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_ALQ DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_ALQ DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_ALQ DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 7_daviviendaPA_DC
-- ## INFORMACION DE DAVIVIENDA PA PARA REPORTAR A DATACREDITO CONSUMO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Davivienda' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-0ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE','CEMCCIM',
'CEMMCIM',
'CERCCIM',
'CERESMICRO',
'CERMCIM',
'SUMOCO',
'SUMOORI',
'SUMOTU'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
        AND PFI.PFICODIGO NOT IN ('CNEGO','CNEGP','TR','UBCL','UBCLP')-- Bajo Monto Libre Inversión, Bajo Monto Motos 'BMLI','BMMO',
		AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAED')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAED')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAED') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAED')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT 
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_DAVIVIENDA DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0') 
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_DAVIVIENDA DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_DAVIVIENDA DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 8_dannPA_DC
-- ## INFORMACION DE DANN PA PARA REPORTAR A DATACREDITO CONSUMO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Dann' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-0ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
        AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR','UBCL','UBCLP')-- Bajo Monto Libre Inversión, Bajo Monto Motos
		AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAEDR')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAEDR')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAEDR') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAEDR')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_DANN DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') 
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_DANN DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_DANN DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 9_daviviendaPA_renumeracion
SELECT 
    CONM.OBLNROOBLIGACION, 
    CONM.RENUMERADO, 
    PERID, 
    SUB.TIDABREVIACION,
    CONM.TIPONEG AS TIPO_NEGOCIO
FROM(
    SELECT 
        OBL.OBLNROOBLIGACION ,
        'R'||OBL.OBLNROOBLIGACION RENUMERADO,
        TIN.TINDESCRIPCION AS TIPONEG
    FROM CO_OBLIGACION OBL
        LEFT JOIN co_saldosobligaciondiario  SOD on SOD.sodnumobligacion  = OBL.OBLNROOBLIGACION  AND SOD.SODFECHA = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-2))
        --ULTIMO DÍA DE HACE DOS MESES SI es 2 de julio la fecha es 31/5
        LEFT JOIN co_saldosobligaciondiario  sod1 on SOD1.sodnumobligacion = OBL.OBLNROOBLIGACION  AND SOD1.SODFECHA = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))
        LEFT JOIN CO_TIPONEGOCIO TIN ON TIN.TINCODIGO = SOD.SODTIPONEGOCIO
    WHERE SOD.SODTIPONEGOCIO IN ('PAEDR','PAED')  
        AND SOD1.SODTIPONEGOCIO NOT IN ('PAEDR','PAED')
    )CONM


INNER JOIN (
-- QUERY PARA SABER CUAL FUE EL ULTIMO PATRIMONIO 
    SELECT * 
    FROM (
        SELECT 
            CASE WHEN TNANT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNACT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN TNANT.TINDESCRIPCION
                 WHEN TNACT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNANT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN TNACT.TINDESCRIPCION 
            ELSE 'OTRO'
            END TIPO_NEGOCIO,
            ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY LOOFECHASISTEMA desc) RNK,
            OBL.OBLNROOBLIGACION
            --,'R'||OBL.OBLNROOBLIGACION AS RENUMERADO
            ,PERID
            , TIDABREVIACION
            ,CASE WHEN TNANT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNACT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN 'SALIDA_PA'
                 WHEN TNACT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNANT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN 'ENTRADA_PA'
            ELSE 'OTRO'
            END CASO
        FROM CO_LOGOPERACION LOA
            INNER JOIN CO_OBLIGACION OBL ON LOA.LOOOBLIGACION = OBL.OBLUUID AND (LOA.TENANT = OBL.TENANT)
            INNER JOIN CO_DEFREGLANEGOCIO DR ON LOA.LOOOPERREGLA = DR.DRNUUID AND (LOA.TENANT = DR.TENANT)
            INNER JOIN CO_ATRIBOPERCAMTIPONEGOCIO CAM ON LOA.LOOUUID = CAM.CTNLOGOPERACION AND (LOA.TENANT = CAM.TENANT)
            INNER JOIN CO_TIPONEGOCIO TNANT ON CAM.CTNTIPONEGOCIOANT = TNANT.TINUUID 
            INNER JOIN CO_TIPONEGOCIO TNACT ON CAM.CTNTIPONEGOCIOACTUAL = TNACT.TINUUID
            INNER JOIN EE_COMPCOM COMP ON COMP.COCUUID = OBL.OBLCLIENTEFINAN
            INNER JOIN EE_TERCERO TER ON TER.TERUUID = COMP.COCPERSONA
            INNER JOIN EE_TIPOIDENT TID ON TID.TIDUUID = TER.PERTIPOIDENT
        WHERE LOA.LOOOPERREGLA IN ('4A63A9870F2C2ADEADAC1C6C8E706572')
            AND LOA.LOOREVERSADO='0'
            AND (TNANT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
            OR TNACT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda'))
            --AND OBL.OBLFCHAINICIO>'01/10/2021'
            --AND LOA.LOOFECHASISTEMA <= TO_DATE('2022/06/30', 'YYYY/MM/DD') 
            --AND OBL.OBLNROOBLIGACION='1713135')
        )
    WHERE RNK = 1) SUB ON SUB.OBLNROOBLIGACION = CONM.OBLNROOBLIGACION


-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('1',1,'1') || -- TIPO DE REGISTROS
    LPAD('12',2,'0') || --  CODIGO PAQUETE CAMBIO---
    LPAD('149',3,'0') || -- TIPO ENTIDAD
    LPAD('395',3,'1') || -- CODIGO ENTIDAD -> DANN 482, DAVIVIENDA 395
    LPAD(' ',10,' ') || -- RESERVADO
    LPAD('2',2,'0') || -- TIPO REPORTE
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMM')||'05' -- FECHA CORTE
    AS REGISTRO_CONTROL
FROM 
    TBL_RENUMERACION_PA DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD('3',1,'0') || -- TIPO DE REGISTRO
    '  '||LPAD(CS.OBLNROOBLIGACION,18,'0') || -- NUMERO DE OBLIGACION ANTERIOR
    LPAD('1',6,'0') || -- CODIGO SUCURSAL
    LPAD(CS.RENUMERADO,20,'0') || -- NUMERO OBLIGACION NUEVA
    LPAD('1',6,'0') || -- CODIGO SUCURSAL 
    CASE 
        WHEN CS.TIDABREVIACION = 'CC' THEN LPAD('01',2,'0') 
        WHEN CS.TIDABREVIACION = 'NIT' THEN LPAD('02',2,'0') 
        WHEN CS.TIDABREVIACION = 'CE' THEN LPAD('03',2,'0') 
        WHEN CS.TIDABREVIACION = 'TI' THEN LPAD('04',2,'0') 
        WHEN CS.TIDABREVIACION = 'PAS' THEN LPAD('05',2,'0') 
        WHEN CS.TIDABREVIACION = 'PEP' THEN LPAD('12',2,'0') 
        ELSE '00'
    END 
    || -- TIPO IDENTIFICACION
    LPAD(CS.PERID,15,'0')  -- NUMERO DE IDENTIFICACION
   
    AS REGISTRO_DETALLE
FROM

  TBL_RENUMERACION_PA CS
  WHERE TIPO_NEGOCIO = 'Patrimonio Autonomo Especial - Davivienda'

--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('9',1,'9') || -- TIPO DE REGISTRO
    LPAD((COUNT(CS.OBLNROOBLIGACION)+2),8,'0') || -- NUMERO DE REGISTROSTOTAL
    LPAD('0',8,'0') || -- NUMERO DE REGISTROS TIPO 2
    LPAD(COUNT(CS.OBLNROOBLIGACION),8,'0') || -- NUMERO DE REGISTROS TIPO 3
    LPAD('0',8,'0')  -- NUMERO DE REGISTRO TIPO 4
    AS CONTROL_ARCHIVO
FROM
  TBL_RENUMERACION_PA CS
WHERE TIPO_NEGOCIO = 'Patrimonio Autonomo Especial - Davivienda'

    --LEFT JOIN ACTUARIA.TBL_RENUMERACION_PA@DBLINKACTUARIA CS ON DC.CREDITO = CS.OBLNROOBLIGACION
   -- WHERE DC.CREDITO IN ('1710988', '1717112', '1721074')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN '1' THEN 1
        WHEN '9' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 10_dannPA_renumeracion
SELECT 
    CONM.OBLNROOBLIGACION, 
    CONM.RENUMERADO, 
    PERID, 
    SUB.TIDABREVIACION,
    CONM.TIPONEG AS TIPO_NEGOCIO
FROM(
    SELECT 
        OBL.OBLNROOBLIGACION ,
        'R'||OBL.OBLNROOBLIGACION RENUMERADO,
        TIN.TINDESCRIPCION AS TIPONEG
    FROM CO_OBLIGACION OBL
        LEFT JOIN co_saldosobligaciondiario  SOD on SOD.sodnumobligacion  = OBL.OBLNROOBLIGACION  AND SOD.SODFECHA = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-2))
        --ULTIMO DÍA DE HACE DOS MESES SI es 2 de julio la fecha es 31/5
        LEFT JOIN co_saldosobligaciondiario  sod1 on SOD1.sodnumobligacion = OBL.OBLNROOBLIGACION  AND SOD1.SODFECHA = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))
        LEFT JOIN CO_TIPONEGOCIO TIN ON TIN.TINCODIGO = SOD.SODTIPONEGOCIO
    WHERE SOD.SODTIPONEGOCIO IN ('PAEDR','PAED')  
        AND SOD1.SODTIPONEGOCIO NOT IN ('PAEDR','PAED')
    )CONM


INNER JOIN (
-- QUERY PARA SABER CUAL FUE EL ULTIMO PATRIMONIO 
    SELECT * 
    FROM (
        SELECT 
            CASE WHEN TNANT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNACT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN TNANT.TINDESCRIPCION
                 WHEN TNACT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNANT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN TNACT.TINDESCRIPCION 
            ELSE 'OTRO'
            END TIPO_NEGOCIO,
            ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY LOOFECHASISTEMA desc) RNK,
            OBL.OBLNROOBLIGACION
            --,'R'||OBL.OBLNROOBLIGACION AS RENUMERADO
            ,PERID
            , TIDABREVIACION
            ,CASE WHEN TNANT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNACT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN 'SALIDA_PA'
                 WHEN TNACT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                    AND TNANT.TINDESCRIPCION NOT IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
                 THEN 'ENTRADA_PA'
            ELSE 'OTRO'
            END CASO
        FROM CO_LOGOPERACION LOA
            INNER JOIN CO_OBLIGACION OBL ON LOA.LOOOBLIGACION = OBL.OBLUUID AND (LOA.TENANT = OBL.TENANT)
            INNER JOIN CO_DEFREGLANEGOCIO DR ON LOA.LOOOPERREGLA = DR.DRNUUID AND (LOA.TENANT = DR.TENANT)
            INNER JOIN CO_ATRIBOPERCAMTIPONEGOCIO CAM ON LOA.LOOUUID = CAM.CTNLOGOPERACION AND (LOA.TENANT = CAM.TENANT)
            INNER JOIN CO_TIPONEGOCIO TNANT ON CAM.CTNTIPONEGOCIOANT = TNANT.TINUUID 
            INNER JOIN CO_TIPONEGOCIO TNACT ON CAM.CTNTIPONEGOCIOACTUAL = TNACT.TINUUID
            INNER JOIN EE_COMPCOM COMP ON COMP.COCUUID = OBL.OBLCLIENTEFINAN
            INNER JOIN EE_TERCERO TER ON TER.TERUUID = COMP.COCPERSONA
            INNER JOIN EE_TIPOIDENT TID ON TID.TIDUUID = TER.PERTIPOIDENT
        WHERE LOA.LOOOPERREGLA IN ('4A63A9870F2C2ADEADAC1C6C8E706572')
            AND LOA.LOOREVERSADO='0'
            AND (TNANT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda')
            OR TNACT.TINDESCRIPCION IN ('Patrimonio Autonomo Especial Dann Regional','Patrimonio Autonomo Especial - Davivienda'))
            --AND OBL.OBLFCHAINICIO>'01/10/2021'
            --AND LOA.LOOFECHASISTEMA <= TO_DATE('2022/06/30', 'YYYY/MM/DD') 
            --AND OBL.OBLNROOBLIGACION='1713135')
        )
    WHERE RNK = 1) SUB ON SUB.OBLNROOBLIGACION = CONM.OBLNROOBLIGACION


-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('1',1,'1') || -- TIPO DE REGISTROS
    LPAD('12',2,'0') || --  CODIGO PAQUETE CAMBIO---
    LPAD('149',3,'0') || -- TIPO ENTIDAD
    LPAD('482',3,'1') || -- CODIGO ENTIDAD -> DANN 482, DAVIVIENDA 395
    LPAD(' ',10,' ') || -- RESERVADO
    LPAD('2',2,'0') || -- TIPO REPORTE
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMM')||'05' -- FECHA CORTE
    AS REGISTRO_CONTROL
FROM 
    TBL_RENUMERACION_PA DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD('3',1,'0') || -- TIPO DE REGISTRO
    '  '||LPAD(CS.OBLNROOBLIGACION,18,'0') || -- NUMERO DE OBLIGACION ANTERIOR
    LPAD('1',6,'0') || -- CODIGO SUCURSAL
    LPAD(CS.RENUMERADO,20,'0') || -- NUMERO OBLIGACION NUEVA
    LPAD('1',6,'0') || -- CODIGO SUCURSAL 
    CASE 
        WHEN CS.TIDABREVIACION = 'CC' THEN LPAD('01',2,'0') 
        WHEN CS.TIDABREVIACION = 'NIT' THEN LPAD('02',2,'0') 
        WHEN CS.TIDABREVIACION = 'CE' THEN LPAD('03',2,'0') 
        WHEN CS.TIDABREVIACION = 'TI' THEN LPAD('04',2,'0') 
        WHEN CS.TIDABREVIACION = 'PAS' THEN LPAD('05',2,'0') 
        WHEN CS.TIDABREVIACION = 'PEP' THEN LPAD('12',2,'0') 
        ELSE '00'
    END 
    || -- TIPO IDENTIFICACION
    LPAD(CS.PERID,15,'0')  -- NUMERO DE IDENTIFICACION
   
    AS REGISTRO_DETALLE
FROM

  TBL_RENUMERACION_PA CS
  WHERE TIPO_NEGOCIO = 'Patrimonio Autonomo Especial Dann Regional'

--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('9',1,'9') || -- TIPO DE REGISTRO
    LPAD((COUNT(CS.OBLNROOBLIGACION)+2),8,'0') || -- NUMERO DE REGISTROSTOTAL
    LPAD('0',8,'0') || -- NUMERO DE REGISTROS TIPO 2
    LPAD(COUNT(CS.OBLNROOBLIGACION),8,'0') || -- NUMERO DE REGISTROS TIPO 3
    LPAD('0',8,'0')  -- NUMERO DE REGISTRO TIPO 4
    AS CONTROL_ARCHIVO
FROM
  TBL_RENUMERACION_PA CS
WHERE TIPO_NEGOCIO = 'Patrimonio Autonomo Especial Dann Regional'

    --LEFT JOIN ACTUARIA.TBL_RENUMERACION_PA@DBLINKACTUARIA CS ON DC.CREDITO = CS.OBLNROOBLIGACION
   -- WHERE DC.CREDITO IN ('1710988', '1717112', '1721074')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN '1' THEN 1
        WHEN '9' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 11_sudamerisPA (NUEVO)
-- ## INFORMACION DE DAVIVIENDA PA PARA REPORTAR A DATACREDITO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Sudameris' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '13'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAEGNB')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAEGNB')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAEGNB') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAEGNB')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_SUDAMERIS DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0') 
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_SUDAMERIS DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_SUDAMERIS DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)




-- 12_daviviendaPA_MC
-- ## INFORMACION DE DAVIVIENDA PA PARA REPORTAR A DATACREDITO MICROCREDITO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'DaviviendaMicro' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-0ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        --AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAEDM')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAEDM')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAEDM') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAEDM')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_DAVIVIENDAMICRO DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('5',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_DAVIVIENDAMICRO DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_DAVIVIENDAMICRO DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 13_dannPA_MC
-- ## INFORMACION DE DANN MICROCREDITO PA PARA REPORTAR A DATACREDITO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'DannMicro' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-0ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        --AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAEDRM')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAEDRM')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAEDRM') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAEDRM')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_DANNMICRO DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('5',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_DANNMICRO DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_DANNMICRO DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 14_bogotaPA_MC
-- ## INFORMACION DE banco de bogota PA PARA REPORTAR A DATACREDITO MICROCREDITO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'BogotaMicro' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-0ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        --AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAEBM')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAEBM')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAEBM') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAEBM')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_BOGOTAMICRO DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('5',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_BOGOTAMICRO DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_BOGOTAMICRO DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 15_bogotaPA_consumo
-- ## INFORMACION DE BANCO DE BOGOTA PA PARA REPORTAR A DATACREDITO CONSUMO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'Bogota' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-0ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        --AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAEIDC')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAEIDC')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAEIDC') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAEIDC')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_BOGOTA DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('5',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_BOGOTA DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_BOGOTA DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 16_CIM_microcredito
-- ## INFORMACION DE DAVIVIENDA PA PARA REPORTAR A DATACREDITO MICROCREDITO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'cimMicro' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        --AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAMCIM')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAMCIM')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAMCIM') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAMCIM')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('490195',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('460243',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('460244',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_CIM_MICRO DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('490195',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('460243',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('460244',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_CIM_MICRO DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_CIM_MICRO DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 17_CIM_consumo
-- ## INFORMACION DE DAVIVIENDA PA PARA REPORTAR A DATACREDITO MICROCREDITO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'cimConsumo' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        --AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PACCIM')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PACCIM')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PACCIM') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PACCIM')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('490195',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('460243',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('460244',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_CIM_CONSUMO DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('490195',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('460243',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('460244',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_CIM_CONSUMO DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_CIM_CONSUMO DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 18_credicorp_consumo
-- ## INFORMACION DE DAVIVIENDA PA PARA REPORTAR A DATACREDITO MICROCREDITO
--## Genera la informacion para reportar a Datacredito de los productos de Patrmonios Autónomos /
SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA
--------------------------------------------------------------------------------

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
        'CredicorpConsumo' TIPO_ARCHIVO,
        ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
        SYSDATE AS FECHA_REPORTE,
        PFI.PFICODIGO AS COD_PRODUCTO,
        PFI.PFIDESCRIPTION AS PRODUCTO,
        NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
        NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
        EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
        OBL.OBLNROOBLIGACION AS CREDITO,
        OBL.OBLFCHAINICIO AS FECHA_INICIO,
        OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
        OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
        CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
        NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
        NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
        EO.ESODESCRIPCION AS ESTADO,
        SEO.SEODESCRIPTION AS SUBESTADO,
        CASE
            WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
            THEN '1'
            WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
            THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- TI: Tarjeta de identidad
            THEN '6'                   
--------------------------------------------------------------------------------
            ELSE 'X'
        END AS TIPO_IDENT,
        TER.PERID AS CEDULA,
        UPPER(
            TRANSLATE(
                REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
             ) AS NOMBRE,
        TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
        CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
            ELSE OBL.OBLVALORCUOTA
        END AS VALORCUOTA,
        NVL(SOD.SODDIASMORA,0) AS DIASMORA,
        OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
        SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
        NVL(SOD.SODVALORMORA,0) AS VALORMORA,
        OBL.OBLDIACORTE AS DIACORTE,
        NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
        NVL(
            TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS CIUDADCORR,
        NVL(
            TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
            ,' ') AS DEPARTAMENTOCORR,
        NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
        NVL(TER.TERTELEFONO,' ') AS TELEFONO,
        COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
        LOWER(COALESCE (EMA.CONINFORMACION,
            TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
        SUBSTR(
            TRANSLATE(
                TRIM(REGEXP_REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                        UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                        DIR.CONINFORMACION,
                                        TER.TERDIRECCION,'0'))
                    ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
                    ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
                    ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
                ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
            ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
        ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
            AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /*  'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                        'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                        'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'DIR'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONAPLICACORRESPONDENCIA = '1'
                )
            ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
        ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'EMA'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP 
        ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-1)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------

    WHERE 1=1 --AND OBL.OBLNROOBLIGACION IN ('764013')
	AND (TI.TINCODIGO NOT IN( 'VENCAVALO') or TI.TINCODIGO is null)
        --AND PFI.PFICODIGO NOT IN ('BMLI','BMMO','CNEGO','CNEGP','TR','UBCL','UBCLP')-- Bajo Monto Libre Inversión, Bajo Monto Motos
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        AND 
            (   
                ((OBL.OBLESTOBLIG = '03' AND SOD.SODTIPONEGOCIO IN ('PAECC')  ) 
                    OR (OBL.OBLESTOBLIG = '04'
                        AND FUP.FECHA_ULTIMOPAGO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Mayor al 01 del mes anterior
                        AND TIOBL.TINCODIGO IN ('PAECC')) -- Estado Obligacion: Cancelada y Fecha Cancelacion: Entre 01 y ultimo dia del Mes Anterior
                )
                AND 
                    ((SOD.SODTIPONEGOCIO IN ('PAECC') 
                        OR ((
                                TRUNC(FUP.FECHA_ULTIMOPAGO,'MM') BETWEEN ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) AND ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Anterior y 01 Del mes Actual
                                AND TIOBL.TINCODIGO IN ('PAECC')
                            ) 
                            -- 
                            )
                        )
                    /*
                    Cartera Propia Esquema Anterior, Cartera Propia Nuevo Esquema, Cartera Propia Nuevo Esquema No Ejecutable, CrediAcceso,
                    Producto Premium, Mi Moto mi Sueño, Cartera Propia Nuevo Esquema Juegos Promocionales, Cartera Propia Esquema Anterior Juegos Promocionales,
                    Credisuyo Consumo ON y MC, Movilidad Eléctrica Nuevo Esquema, Crediplan, Cartera Propia Nuevo Esquema con GM, CrediClub,
                    */
                    )
                AND (EJEC.FECHA_INGRESO >= ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- 01 Del mes Actual
                    OR EJEC.FECHA_INGRESO IS NULL OR TIOBL.TINCODIGO IN ('CPNENE','0013') OR SOD.SODTIPONEGOCIO IN ('CPNENE'))
            )
--------------------------------------------------------------------------------
) WHERE 1=1
---AND DIASMORA < 30 -- *********** TEMPORAL SOLO PARA EJECUCION EL 01 DE ENERO DE 2020 ***************** --- 
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('490195',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('460243',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('460244',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    ACT_ESTRUCTURA_PA_CREDICOPR_CONSUMO DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('460180',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Dann' THEN LPAD('180075',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Sudameris' THEN LPAD('180157',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DaviviendaMicro' THEN LPAD('490092 ',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'DannMicro' THEN LPAD('490166',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'Bogota' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'BogotaMicro' THEN LPAD('460224',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimMicro' THEN LPAD('490195',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'cimConsumo' THEN LPAD('460243',6,'0')
        WHEN DC.TIPO_ARCHIVO =  'CredicorpConsumo' THEN LPAD('460244',6,'0')
        -- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    ACT_ESTRUCTURA_PA_CREDICOPR_CONSUMO DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    ACT_ESTRUCTURA_PA_CREDICOPR_CONSUMO DC
--WHERE COD_PRODUCTO NOT IN ('BMLI', 'BMMO')
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)



-- 19_avalogic
-- ## INFORMACION DE CONSUMO PARA REPORTAR A DATACREDITO
--/ Genera la informacion para reportar a Datacredito de los productos de Consumo /
----- ORIGINAL
SELECT 
TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    CCFVALOR VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,
    ULT_CUOTA
    FROM
(SELECT
    TIPO_ARCHIVO,
    FECHA_REPORTE,
    COD_PRODUCTO,
    PRODUCTO,
    CODETIPONEGOCIO,
    TIPO_NEGOCIO,
    FECHA_EJECUCION,
    CREDITO,
    FECHA_INICIO,
    FECHA_VENC,
    VLRDESEMBOLSO,
    SALDOK,
    CUOTAS,
    CUOTASCANCELADAS,
    CUOTASMORA,
    ESTADO,
    SUBESTADO,
    TIPO_IDENT,
    CEDULA,
    NOMBRE,
    TIPO_DEUDOR,
    VALORCUOTA,
    DIASMORA,
    FECHALIMITE,
    FECHAULTIMOPAGO,
    VALORMORA,
    DIACORTE,
    COD_CIUDADCORR,
    CIUDADCORR,
    DEPARTAMENTOCORR,
    COD_DEPARTAMENTOCORR,
    TELEFONO,
    MOVIL,
    CORREO_ELECTRONICO,
    DIRECCION,
    CCFVALOR,

--------------------------------------------------------------------------------
    CASE 
        WHEN ULT_CUOTA IS NULL THEN 0
    ELSE 1
    END AS ULT_CUOTA,
    
-----------------
CASE
WHEN TIPO_DEUDOR = 'CO' AND CREDITO IN ('999') THEN 1
ELSE 0 END AS EXCLUSION

FROM (
--------------------------- BASE MAESTRO DATACREDITO ---------------------------
    SELECT
    'Avalogic' TIPO_ARCHIVO,
    ROW_NUMBER() OVER (PARTITION BY SOD.SODNUMOBLIGACION ORDER BY SOD.SODFECHA DESC NULLS LAST) AS LVL,
    SYSDATE AS FECHA_REPORTE,
    PFI.PFICODIGO AS COD_PRODUCTO,
    PFI.PFIDESCRIPTION AS PRODUCTO,
    NVL(STN.TINCODIGO, TIOBL.TINCODIGO) AS CODETIPONEGOCIO,
    NVL(STN.TINDESCRIPCION, TIOBL.TINDESCRIPCION) AS TIPO_NEGOCIO,
    EJEC.FECHA_INGRESO AS FECHA_EJECUCION,
    OBL.OBLNROOBLIGACION AS CREDITO,
    OBL.OBLFCHAINICIO AS FECHA_INICIO,
    OBL.OBLFEVENCIMIENTO AS FECHA_VENC,
    OBL.OBLVLRDESEMBOLSO AS VLRDESEMBOLSO,
    CUO.CCFVALOR,
--------------------------------------------------------------------------------
        CASE
            WHEN PFI.PFICODIGO IN ('ALQ','ALCC') THEN NVL(SOD.SODSALDOTOTAL,0) -- Alquila
            ELSE NVL(SOD.sodsaldototal,0)
        END AS SALDOK,

        NVL((OBL.OBLCUOTASORDPAGADAS + OBL.OBLCUOTASORDSINPAGAR),OBL.OBLPLAZO) AS CUOTAS,
--------------------------------------------------------------------------------
    NVL(SOD.SODCUOTASORDPAGADAS, OBL.OBLCUOTASORDPAGADAS) AS CUOTASCANCELADAS,
    NVL(SOD.SODNUMEROCUOTASENMORA,0) AS CUOTASMORA,
    EO.ESODESCRIPCION AS ESTADO,
    SEO.SEODESCRIPTION AS SUBESTADO,
    CASE
        WHEN TID.TIDABREVIACION = 'CC' -- CC: Cédula de Ciudadanía
        THEN '1'
        WHEN TID.TIDABREVIACION = 'NIT' -- NIT: NIT
        THEN '2'
--------------------------------------------------------------------------------
            WHEN TID.TIDABREVIACION IN ('CE') -- CE: Cédula de extranjería
            THEN '4'
            WHEN TID.TIDABREVIACION IN ('PASA') -- PASA: Pasaporte
            THEN '5'
            WHEN TID.TIDABREVIACION IN ('TI') -- TI: Tarjeta de identidad
            THEN '7'
            WHEN TID.TIDABREVIACION IN ('PPT') -- PPT
            THEN '6'            
--------------------------------------------------------------------------------
        ELSE 'X'
    END AS TIPO_IDENT,
    TER.PERID AS CEDULA,
    UPPER(
        TRANSLATE(
            REPLACE(TER.PERPRIMERAPELLIDO,' ','')||' '||REPLACE(TER.PERSEGUNDOAPELLIDO,' ','')||' '||REPLACE(TER.PERNOMBRES,'  ',' ')
        ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
         ) AS NOMBRE,
    TD.CLFTIPODEUDOR AS TIPO_DEUDOR,
    CASE
            WHEN PFI.PFICODIGO IN ('CCLUB','ALCC') THEN (OBL.OBLVALORCUOTA * 22) -- Crediclub
            WHEN PFI.PFICODIGO IN ('UBC2Q') THEN (OBL.OBLVALORCUOTA * 2) -- Ubicados Quincenal
            WHEN PFI.PFICODIGO IN ('ALQ','GOC','CRAL') THEN (OBL.OBLVALORCUOTA * 4) -- Alquila
    ELSE OBL.OBLVALORCUOTA
    END AS VALORCUOTA,
        CASE
            WHEN PFI.PFICODIGO IN ('SUMTO') AND NVL(SOD.SODDIASMORA,0)>539  THEN 539-- MORA SUMOTO
            ELSE NVL(SOD.SODDIASMORA,0)
        END AS DIASMORA,    
    OBL.OBLFECHALIMITEPAGO AS FECHALIMITE,
    SOD.SODFECHAULTIMOPAGO AS FECHAULTIMOPAGO,
    NVL(SOD.SODVALORMORA,0) AS VALORMORA,
    OBL.OBLDIACORTE AS DIACORTE,
    NVL(CIUCORRESP.CIUCODIGO,0) AS COD_CIUDADCORR,
    NVL(
        TRANSLATE(CIUCORRESP.CIUNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,' ') AS CIUDADCORR,
    NVL(
        TRANSLATE(DEPCORRESP.DEPNOMBRE,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
        ,' ') AS DEPARTAMENTOCORR,
    NVL(DEPCORRESP.DEPCODIGO,0) AS COD_DEPARTAMENTOCORR,
    NVL(TER.TERTELEFONO,' ') AS TELEFONO,
    COALESCE (CEL.CONINFORMACION, TER.TERCELULAR,' ') AS MOVIL,
    LOWER(COALESCE (EMA.CONINFORMACION,
    TER.TERCORREOELECTRONICO,'notiene@notiene.com')) AS CORREO_ELECTRONICO,
    SUBSTR(
    TRANSLATE(
        TRIM(REGEXP_REPLACE(REPLACE(
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                UPPER(COALESCE (TD.CLFINFCORRESPONDENCIA,
                                DIR.CONINFORMACION,
                                TER.TERDIRECCION,'0'))
            ,'CALLE','CL'),'CARRERA','CR'),'CRA','CR'),'AVENIDA','AV'),'TRANSVERSAL','TR'),'ZONA','ZN'),'MANZANA','MZ'),'DIAGONAL','DG'),'DIAG','DG'),'CARRETERA','CT'),'VEREDA','VR'),'INTERIOR','INT'),'APARTAMENTO','AP')
            ,'APTO','AP'),'APT','AP'),'BARRIO','BR'),'CASA','CS'),'BLOQUE','BQ'),'BLQUE','BQ'),'SECTOR','SC'),'URBANIZACION','UB'),'URBANIZACIÓN','UB'),'SEGUNDO','2°'),'PRIMER PISO','PISO 1'),'FINCA','FI'),'NORTE','(N)')
            ,'SUR','(S)'),'ESTE','(E)'),'OESTE','(O)'),'UNIDAD','UN'),'UNIDAD RESIDENCIAL','UR'),'TORRE','TO'),'CONJUNTO RESIDENCIAL','CO'),'CONJUNTO','CO'),'CIUDADELA','CD'),'CIRCUNVALAR','CV'),'LOCAL','LC'),' ',' ')
        ,',',', '), '[^A-Za-z0-9ÁÉÍÓÚáéíóú ]', ''))
    ,'ñáéíóúàèìòùãõâêîôôäëïöüçÑÁÉÍÓÚÀÈÌÒÙÃÕÂÊÎÔÛÄËÏÖÜÇ','naeiouaeiouaoaeiooaeioucNAEIOUAEIOUAOAEIOOAEIOUC')
    ,1,50) AS DIRECCION

--------------------------------------------------------------------------------
    ,VUC.OBLUUID AS ULT_CUOTA
--------------------------------------------------------------------------------

    FROM PRDCCION.CO_OBLIGACION OBL
        INNER JOIN PRDCCION.CO_SOLICITUD SOL ON OBL.TENANT = SOL.TENANT AND (OBL.OBLSOLICITUD = SOL.SOLUUID)
        INNER JOIN PRDCCION.CO_CLTFINANCIERO TD ON SOL.TENANT = TD.TENANT AND (SOL.SOLUUID = TD.CLFSOLICITUD) 
        AND (TD.CLFTIPODEUDOR = 'TI' OR (TD.CLFTIPODEUDOR = 'CO' AND TD.CLFESTADOSOL = 4)) -- Codeudor Aprobado 
        LEFT JOIN PRDCCION.EE_COMPCOM CC ON TD.COCUUID = CC.COCUUID
        LEFT JOIN PRDCCION.EE_TERCERO TER ON CC.COCPERSONA = TER.TERUUID AND CC.TENANT = TER.TENANT
        LEFT JOIN PRDCCION.EE_TIPOIDENT TID ON TER.PERTIPOIDENT = TID.TIDUUID
        
        LEFT JOIN PRDCCION.CO_ESTADOOBLIGACION EO ON OBL.OBLESTOBLIG = EO.ESOCODIGO
        LEFT JOIN PRDCCION.CO_SUBESTADOOBLIG SEO ON OBL.OBLSUBESTOBLIG = SEO.SEOCODE
------------- ### FILTRO SODFECHA ULTIMO DIA DEL MES ANTERIOR ### --------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON SOD.SODOBLIGACION = OBL.OBLUUID AND SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0)  -- ## Primer dia del mes actual
--------------------------------------------------------------------------------
        LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SODTIN ON SODTIN.SODOBLIGACION = OBL.OBLUUID AND SODTIN.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1) -- ## Primer dia del mes anterior
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TI ON TI.TINCODIGO = SODTIN.SODTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO TIOBL ON TIOBL.TINUUID = OBL.OBLTIPONEGOCIO
        LEFT JOIN PRDCCION.CO_TIPONEGOCIO STN ON STN.TINUUID = SOD.SODTIPONEGOCIO
        --
        LEFT JOIN PRDCCION.CO_CONTRATOFCRO CFRO ON OBL.OBLCONTRATOFINAN = CFRO.CFROUUID
        LEFT JOIN PRDCCION.CO_DEFPRODFINAN PFI ON CFRO.CFROPRODFRO = PFI.PFICODIGO
        LEFT JOIN PRDCCION.GE_CIUDAD CIUCORRESP ON CIUCORRESP.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPCORRESP ON DEPCORRESP.DEPCODIGO = CIUCORRESP.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAICORRESP ON PAICORRESP.PAICODIGO = DEPCORRESP.DEPPAIS
        LEFT JOIN PRDCCION.GE_CIUDAD CIURESI ON CIURESI.CIUCODIGO = TD.CLFCIUDCORRESP
        LEFT JOIN PRDCCION.GE_DEPARTAMENTO DEPRESI ON DEPRESI.DEPCODIGO = CIURESI.CIUDEPARTAMENTO
        LEFT JOIN PRDCCION.GE_PAIS PAIRESI ON PAIRESI.PAICODIGO = DEPRESI.DEPPAIS
-- INFORMACION DE FECHA EJECUCION ----------------------------------------------
        LEFT JOIN
            (SELECT
                CREDITO
                ,FECHA_INGRESO
            FROM
            (
                SELECT OBL.OBLNROOBLIGACION AS CREDITO
                    ,TN.TINDESCRIPCION TIPONEGOCIOACTUAL
                    ,LG.LOOFECHAOPERACION FECHA_INGRESO
                    ,LG.LOOFECHASISTEMA FECHA_APL
                    ,ROW_NUMBER() OVER (PARTITION BY OBL.OBLNROOBLIGACION ORDER BY LG.LOOFECHASISTEMA ASC) ROWN
                FROM PRDCCION.CO_OBLIGACION OBL
                    INNER JOIN PRDCCION.CO_LOGOPERACION LG ON LG.LOOOBLIGACION = OBL.OBLUUID AND LG.TENANT = OBL.TENANT
                    INNER JOIN PRDCCION.CO_ATRIBOPERCAMTIPONEGOCIO ATB ON ATB.TENANT = LG.TENANT AND ATB.CTNLOGOPERACION = LG.LOOUUID
                    INNER JOIN PRDCCION.CO_TIPONEGOCIO TN ON ATB.CTNTIPONEGOCIOACTUAL = TN.TINUUID
                WHERE LG.LOOREVERSADO = 0
                    AND LG.LOOOPERREGLA = '4A63A9870F2C2ADEADAC1C6C8E706572' -- OPECAMTINE: Cambio Tipo Negocio
                    AND TN.TINCODIGO IN ('CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002')
                    /* 'Cartera Castigada Afianzadora GranColombiana','Cartera Castigada Inversiones Repauto','Cartera Ejecutada Moviaval',
                    'Cartera Ejecutada Afianzadora Gran Colombiana','Cartera Ejecutada Resfin','Cartera Esquema Anterior Descuento 1',
                    'Cartera Propia Nuevo Esquema No Ejecutable','MicroCrédito no Ejecutable'
                    */
            )
            WHERE ROWN=1
            ) EJEC
        ON EJEC.CREDITO = OBL.OBLNROOBLIGACION
------------ FILTRO FECHA EJECUCION MAYOR O IGUAL AL 01 DEL MES ANTERIOR -------
--ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Mayor o igual al 01 del mes anterior
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE DIRECCION ----------------------------------------------------
        (SELECT * FROM (
            (SELECT
                ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                CON.CONPERNATJUR,
                CON.CONINFORMACION
            FROM PRDCCION.EE_CONTACTO CON
            WHERE CONFORMACONTACTO = 'DIR'
                AND CONESTADO = 'ACT'
                AND CPCTIPOGESTIONADO = 'CLIE'
                AND CONAPLICACORRESPONDENCIA = '1'
            )
        ) WHERE RNK=1)DIR
        ON DIR.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DEL CELULAR -----------------------------------------------------
            (SELECT * FROM (
                (SELECT
                    ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                    CON.CONPERNATJUR,
                    CON.CONINFORMACION
                FROM PRDCCION.EE_CONTACTO CON
                WHERE CONFORMACONTACTO = 'CEL'
                    AND CONESTADO = 'ACT'
                    AND CPCTIPOGESTIONADO = 'CLIE'
                    AND CONCONTACTOCONFIRMADO = '1'
                )
            ) WHERE RNK=1)CEL
            ON CEL.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
        LEFT JOIN
-- INFORMACION DE CORREO -------------------------------------------------------
        (SELECT * FROM (
            (SELECT
                ROW_NUMBER() OVER(PARTITION BY CON.CONPERNATJUR ORDER BY CONFECHAULTACTUALIZACION DESC) RNK,
                CON.CONPERNATJUR,
                CON.CONINFORMACION
            FROM PRDCCION.EE_CONTACTO CON
            WHERE CONFORMACONTACTO = 'EMA'
                AND CONESTADO = 'ACT'
                AND CPCTIPOGESTIONADO = 'CLIE'
                AND CONCONTACTOCONFIRMADO = '1'
            )
        ) WHERE RNK=1)EMA
        ON EMA.CONPERNATJUR = TER.TERUUID
--------------------------------------------------------------------------------
-- INFORMACION FECHA ULTIMO PAGO -----------------------------------------------
        LEFT JOIN
            (SELECT
                MAX(LOO.LOOFECHASISTEMA) FECHA_ULTIMOPAGO
                ,LOO.LOOOBLIGACION UUID_OBLIGACION
            FROM PRDCCION.CO_LOGOPERACION LOO
            WHERE LOO.LOOOPERREGLA IN ('4702505DE3A5FA633EAC1C6C9A706572','48A8A7861886F0BADDAC1C6C8E666E69')
                -- Aplicación Pago, Aplicación Otras Fuentes
            GROUP BY
                LOO.LOOOBLIGACION
            ) FUP ON FUP.UUID_OBLIGACION = OBL.OBLUUID --'553C56B53A33EF0A0AAC1A608C4F626C'
--------------------------------------------------------------------------------
-- INFORMACION VALOR ULTIMA CUOTA ----------------------------------------------
    LEFT JOIN
        (SELECT 
            OBLUUID
        FROM (
        SELECT DISTINCT
            OBL.OBLUUID
            ,OBL.OBLNROOBLIGACION
            ,OBL.OBLESTOBLIG
            ,SOD.SODTIPONEGOCIO
            ,SOD.SODDIASMORA
            ,SOD.SODVALORCUOTA
            ,SOD.SODVALORMORA
            ,SOD.SODVALORULTPAGO
            ,ROUND(ULT.CCFVALOR,2) AS VLR_ULTIMA_CUOTA
            ,ROUND((ULT.CCFVALOR*0.10),2) AS PORCENTAJE
            ,CASE  
                WHEN ULT.CCFVALOR > (SOD.SODVALORCUOTA*0.10) THEN 'Aplica'
                ELSE 'No Aplica'
            END AS SUPERA_10PC
            ,ROW_NUMBER() OVER (PARTITION BY ULT.OBLNROOBLIGACION ORDER BY CCFFECHA DESC, 
                CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                    WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                    WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                    WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                END DESC) RNK
            ,SOD.SODCUOTASORDSINPAGAR
            ,GES.GESID
            ,GES.GESESTADOACUERDO
        FROM PRDCCION.CO_OBLIGACION OBL 
            LEFT JOIN PRDCCION.CO_SALDOSOBLIGACIONDIARIO SOD ON OBL.OBLNROOBLIGACION = SOD.SODNUMOBLIGACION
            LEFT JOIN PRDCCION.CO_GESTION GES ON OBL.OBLNROOBLIGACION = GES.GESIDGESTIONABLE --AND GES.GESESTADOACUERDO = 'VGT'
        --------------------------------------------------------------------------------
            LEFT JOIN 
                (SELECT DISTINCT 
                    CTO.CFROUUID
                    ,OBL.OBLUUID
                    ,OBL.OBLNROOBLIGACION
                    ,FLU1.CCFCONTRATOFINAN
                    ,FLU1.CCFCUOTANUMERO
                    ,FLU1.CCFFECHA
                    ,FLU1.CCFVALOR
                    ,EST.EPGDESCRIPTION
                FROM PRDCCION.CO_CUOTATIPOCPTO FLU   
                    INNER JOIN PRDCCION.CO_CUOTACTROFINANC FLU1 ON(FLU1.TENANT = FLU.TENANT AND FLU1.CCFUUID = FLU.CTCCUOTACTROFINAN)   
                    INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON FLU1.CCFESTADOPAGO = EST.EPGCODE
                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUID = FLU1.CCFCONTRATOFINAN AND CTO.CFROESVIGENTE = 1
                    INNER JOIN PRDCCION.CO_OBLIGACION OBL ON OBL.OBLUUID = CTO.CFROUUIDDUENO AND OBL.OBLESTOBLIG IN ('03','04','05')
                WHERE 1=1
                    AND FLU.TENANT=3 
                    --AND OBL.OBLNROOBLIGACION = '1371049'
                ORDER BY FLU1.CCFFECHA NULLS FIRST
                ) ULT ON ULT.OBLUUID = OBL.OBLUUID
        --------------------------------------------------------------------------------
        WHERE SOD.SODFECHA = ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- ## Primer dia del mes actual
            AND SOD.SODCUOTASORDSINPAGAR = 1 -- ULTIMA CUOTA SIN PAGAR
            AND SOD.SODDIASMORA > 30 -- CON DIAS EN MORA
            AND SOD.SODTIPONEGOCIO -- Tipo Negocio
                NOT IN (
                        '0015',
                        '0016',
                        'CVAGC7',
                        'CCIR',
                        'CEMOVI',
                        'CVAGC10',
                        'CERESFI',
                        'PA',
                        '4002',
                        '4003',
                        '0012',
                        'CPNENE',
                        'CVADANN',
                        'CVAIR',
                        '3003',
                        'CCPROPIA',
                        'CJAGC',
                        '5003',
                        '5002',
                        'CJCVIR',
                        '6003',
                        '6013',
                        '6012',
                        '0013',
                        'LIBRANZANE',
						'CEMCCIM',
'CEMMCIM',
'CERCCIM',
'CERESMICRO',
'CERMCIM',
'SUMOCO',
'SUMOORI',
'SUMOTU'
                        )
            AND GES.GESORIGES = '541A7452E6486C9C8EAC1C6C86662A70' -- Gestión de Cobros
            --AND GES.GESTIPOGESTION IN ('ACPD') -- Acuerdo con Descuento
            AND GES.GESCAMPANADESC IN ('ULCUO') -- Campaña Descuento: Ultima Cuota
            --AND OBL.OBLNROOBLIGACION = 1371049
        ) WHERE RNK=1 AND SUPERA_10PC = 'Aplica' --AND OBLNROOBLIGACION = CREDITO
        ) VUC ON VUC.OBLUUID = OBL.OBLUUID
        
    INNER JOIN (SELECT 
                    CCFCUOTANUMERO AS NUMERO_CUOTA,
                    OBLNROOBLIGACION,
                    PFIDESCRIPTION AS PRODUCTO, 
                    EPGDESCRIPTION AS ESTADO_PAGO,
                    CCFFECHA AS FECHA_CUOTA,
                    OBLPLAZO AS PLAZO,
                    OBLVLRDESEMBOLSO AS DESEMBOLSO,
                    CCFVALOR
                FROM    (SELECT 
                            DISTINCT OBLNROOBLIGACION,OBLPLAZO
                            ,OBL.OBLVLRDESEMBOLSO
                            ,OBLESTOBLIG,CCFCUOTANUMERO
                            ,CCFFECHA,CCFVALOR,PFIDESCRIPTION
                            ,EPGDESCRIPTION,CFROUUID
                            ,ROW_NUMBER() OVER (PARTITION BY OBLNROOBLIGACION ORDER BY CCFFECHA, 
                                                                                        CASE WHEN EPGDESCRIPTION = 'Pago Completo' THEN 1
                                                                                        WHEN EPGDESCRIPTION = 'Pago Incompleto' THEN 2
                                                                                        WHEN EPGDESCRIPTION = 'Por Pagar' THEN 3
                                                                                        WHEN EPGDESCRIPTION = 'Vencida' THEN 4
                                                                                        END ASC) RNK
                        FROM    (SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 1
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-0)
                                UNION
                                SELECT 
                                    OBL.OBLNROOBLIGACION,OBL.OBLPLAZO,OBL.OBLVLRDESEMBOLSO,OBL.OBLESTOBLIG,CTO.CFROUUID,PD.PFIDESCRIPTION
                                FROM PRDCCION.CO_OBLIGACION OBL
                                    INNER JOIN PRDCCION.CO_CONTRATOFCRO CTO ON CTO.CFROUUIDDUENO = OBL.OBLUUID
                                    LEFT JOIN PRDCCION.CO_DEFPRODFINAN PD ON CTO.CFROPRODFRO = PD.PFICODIGO
                                WHERE CTO.CFROESVIGENTE = 0
                                    AND OBL.OBLESTOBLIG IN ('03','04','05')
                                    --AND OBL.OBLFCHAINICIO>= TRUNC(SYSDATE-0)
                                ) OBL
                            LEFT JOIN   (SELECT 
                                            DISTINCT Flu1.CCFCONTRATOFINAN,Flu1.CCFCUOTANUMERO,Flu1.CCFFECHA,Flu1.CCFVALOR,EST.EPGDESCRIPTION
                                        FROM PRDCCION.CO_CUOTATIPOCPTO Flu   
                                            INNER JOIN PRDCCION.CO_CUOTACTROFINANC Flu1 ON(Flu1.tenant =Flu.tenant and Flu1.CCFUUID=Flu.CTCCUOTACTROFINAN)   
                                            INNER JOIN PRDCCION.CO_ESTADOPAGO EST ON Flu1.CCFESTADOPAGO = EST.EPGCODE
                                        WHERE (Flu1.CCFESTADOPAGO IN (1,2,3,4) AND Flu.CTCESTADOPAGO IN (1,2,3,4)) 
                                            AND Flu.tenant=3 
                                        ORDER BY Flu1.CCFFECHA NULLS FIRST
                                        ) CUO ON CUO.CCFCONTRATOFINAN = OBL.CFROUUID
                        WHERE 1=1--OBLNROOBLIGACION='596645'
                            AND CCFCUOTANUMERO='1'
                        )
                WHERE RNK=1) CUO ON CUO.OBLNROOBLIGACION = OBL.oblnroobligacion
--------------------------------------------------------------------------------
    WHERE 1=1 
        AND SOD.SODTIPONEGOCIO  IN ('VENCAVALO')
        AND OBL.OBLFCHAINICIO < ADD_MONTHS(TRUNC(SYSDATE,'MM'),-0) -- Estado Obligacion: Activa y Fecha Inicio < 01 del Mes Actual
        
--------------------------------------------------------------------------------
) WHERE 1=1
)
WHERE EXCLUSION =0
ORDER BY CREDITO

-- reporte
------------------------- MAESTRO DATACREDITO TXT ------------------------------
--------------------------------------------------------------------------------

----ORIGINAL
SELECT
*
FROM
(
-- REGISTRO DE CONTROL
SELECT DISTINCT
    LPAD('H',18,'H') || -- INDICADOR DE REGISTRO INICIAL
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Avalogic' THEN LPAD('286387',6,'0')		-- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- COD SUSCRIPTOR
    LPAD('44',2,'0') || -- TIPO CUENTA
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -1)
    LPAD('M',1,'0') || -- AMPLIACION MILENIO
    LPAD('0',1,'0') || -- INDICADOR DE VALORES EN MILES
    LPAD('T',1,'0') || -- TIPO DE ENTREGA
    LPAD('0',8,'0') || -- FECHA DE INICIO REPORTE (01 MES ANTERIOR)
    LPAD('0',8,'0') || -- FECHA DE FIN REPORTE (ULLTIMO DÍA DEL MES ANTERIOR)
    LPAD('N',1,'0') || -- INDICADOR DE PARTIR
    LPAD('0',746,'0') -- Espacio Reservado de 746 caracteres de longitud
    AS REGISTRO_CONTROL
FROM 
    TBL_AVALOGIC DC
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTROS CON INFORMACION DE CLIENTES
SELECT
    LPAD(DC.TIPO_IDENT,1,'0') || -- TIPO DE IDENTIFICACION
    LPAD(DC.CEDULA,11,'0') || -- NUMERO DE IDENTIFICACION
    LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
    RPAD(UPPER(DC.NOMBRE),45,' ') || -- NOMBRE COMPLETO (MAYÚS)
    LPAD('0',1,'0') || -- SITUACION DEL TITULAR (DEFAULT 0)
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
    TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA DE VENCIMIENTO
    CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('00',2,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('05',2,'0') 
        ELSE '00'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR (DEFAULT 00) -- Ver Anexo 2.2
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('5',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO = 'Venta Cartera Moviaval Microcredito' THEN LPAD('5',1,'0')
            WHEN DC.TIPO_ARCHIVO = 'Moviaval' AND DC.TIPO_NEGOCIO NOT IN 'Venta Cartera Moviaval Microcredito' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('2',1,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('2',1,'0')
		WHEN DC.TIPO_ARCHIVO = 'Avalogic' THEN LPAD('2',1,'0')
    ELSE LPAD('2',1,'0')
    END
    || -- TIPO DE OBLIGACION -- Ver Anexo 2.3
    LPAD('0',1,'0') || -- SUBSIDIO HIPOTECARIO -- Aplica para Tipos de Obligación '3' según anexo 2.3
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA DE SUBSIDIO
    LPAD('1',1,'0') || -- TERMINO DEL CONTRATO QUE GENERA LA OBLIGACIÓN
    CASE
        WHEN DC.DIASMORA > 30 THEN LPAD('0',1,'0') 
        ELSE LPAD('1',1,'0') 
    END || -- FORMA DE PAGO
    LPAD('1',1,'0') || -- PERIODICIDAD DE PAGO (1 - Mensual)
    --LPAD('01',2,'0') || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0') -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('12',2,'0') -- 12 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
        WHEN DC.DIASMORA < 60 THEN LPAD('06',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('07',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('08',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA >= 120 THEN LPAD('09',2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
    END 
    || -- NOVEDAD (DEFAULT 01) -- Ver Anexo 2.5
    LPAD('0',1,'0') || -- ESTADO ORIGEN DE LA CUENTA (DEFAULT 0) Ver Anexo 2.6
    TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA ESTADO ORIGEN
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('03',2,'0')
        WHEN DC.CODETIPONEGOCIO IN ('6013','6012','CPNENE','CCIR','CVAGC10','CVAGC7','CEMOVI','CERESFI','6003','4002','0013') 
            THEN LPAD('05',2,'0') -- 05 CARTERA CASTIGADA
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('01',2,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA > 30 THEN LPAD('02',2,'0')
        ELSE LPAD('01',2,'0')
    END 
    || -- ESTADO DE LA CUENTA (DEFAULT 01) -- Ver Anexo 2.7
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA ESTADO DE LA CUENTA (ULTIMO DIA MES ANTERIOR) (DEFAULT: SYSDATE-1)
    LPAD('0',1,'0') || -- ESTADO DEL PLASTICO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ESTADO DEL PLASTICO
    LPAD('0',1,'0') || -- ADJETIVO
    LPAD('0',8,'0') || -- TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA ADJETIVO
    LPAD('0',1,'0') || -- CLASE TARJETA
    LPAD('0',1,'0') || -- FRANQUICIA
    LPAD(' ',30,' ') || -- NOMBRE MARCA PRIVADA
    LPAD('1',1,'0') || -- TIPO DE MONEDA
    CASE 
        WHEN DC.COD_PRODUCTO = 'BMLI' THEN LPAD('0',1,'0')
        WHEN DC.COD_PRODUCTO = 'ALQ' THEN LPAD('1',1,'0')   -- VALIDAR SI APLICA PARA ALQUILA
        WHEN DC.COD_PRODUCTO = 'ALCO' THEN LPAD('1',1,'0')  -- VALIDAR SI APLICA PARA ALQUILA
        ELSE LPAD('1',1,'0')
    END 
    || -- TIPO DE GARANTIA (DEFAULT 1) -- Ver Anexo 2.9
    LPAD(' ',2,' ') || -- CALIFICACION
    LPAD('0',3,'0') || -- PROBABILIDAD DE INCUMPLIMIENTO
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        WHEN DC.DIASMORA > 999 THEN LPAD('999',3,'0')
        ELSE LPAD(DC.DIASMORA,3,'0')
    END
    || -- EDAD DE MORA
    LPAD(CAST(DC.VLRDESEMBOLSO AS INT),11,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)    
    LPAD(CAST(DC.SALDOK AS INT),11,'0') || -- SALDO DEUDA (SALDO K)
    LPAD('0',11,'0') || -- VALOR DISPONIBLE
    LPAD(CAST(DC.VALORCUOTA AS INT),11,'0') || -- VALOR CUOTA MENSUAL (VALOR CUOTA)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',11,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',11,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',11,'0')
        ELSE LPAD(CAST(DC.VALORMORA AS INT),11,'0') 
    END
    || -- VALOR MORA (VALOR MORA)
    LPAD(DC.CUOTAS,3,'0') || -- TOTAL CUOTAS (PLAZO PACTADO)
    LPAD(DC.CUOTASCANCELADAS,3,'0') || -- CUOTAS CANCELADAS (CUOTAS CANCELADAS)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        -------------------- ---------------------------------------------------
        WHEN DC.ULT_CUOTA = 1 THEN  LPAD('0',3,'0') -- ULTIMA CUOTA AL DIA
        -------------------- ---------------------------------------------------
        WHEN DC.DIASMORA < 30 THEN LPAD('0',3,'0')
        ELSE LPAD(DC.CUOTASMORA,3,'0')
    END
    || -- CUOTAS MORA (CUOTAS MORA)    
    LPAD('0',3,'0') || -- CLAUSULA DE PERMANENCIA
    LPAD('0',8,'0') || --TO_CHAR('00000000', 'YYYYMMDD') || -- FECHA CLAUSULA DE PERMANENCIA
    LPAD(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1), 'YYYYMM')||TO_CHAR(DC.FECHALIMITE, 'DD'),8,'0') || -- FECHA LIMITE DE PAGO
    LPAD(NVL(TO_CHAR(DC.FECHAULTIMOPAGO, 'YYYYMMDD'),0),8,'0') || -- FECHA PAGO (AAAAMMDD)
    RPAD('POR DEFINIR',30,' ') || -- OFICINA DE RADICACION
    RPAD('Medellin',20,' ') || -- CIUDAD DE RADICACION
    RPAD('05001',8,'0') || -- CODIGO DANE CIUDAD DE RADICACION
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE CIUDAD DE RESIDENCIA O CODIGO DANE CIUDAD COMERCIAL
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO RESIDENCIA O DEPARTAMENTO COMERCIAL
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE RESIDENCIA O DIRECCION COMERCIAL
    LPAD(DC.TELEFONO,12,'0') || -- TELEFONO DE RESIDENCIA O TELÉFONO COMERCIAL
    RPAD(' ',20,' ') || -- CIUDAD LABORAL
    RPAD('0',8,'0') || -- CODIGO DANE CIUDAD LABORAL
    RPAD(' ',20,' ') || -- DEPARTAMENTO LABORAL
    RPAD(' ',60,' ') || -- DIRECCION LABORAL
    LPAD('0',12,'0') || -- TELEFONO LABORAL
    RPAD(DC.CIUDADCORR,20,' ') || -- CIUDAD DE CORRESPONDENCIA
    RPAD(DC.COD_CIUDADCORR,8,'0') || -- CODIGO DANE DE CORRESPONDENCIA
    RPAD(DC.DEPARTAMENTOCORR,20,' ') || -- DEPARTAMENTO DE CORRESPONDENCIA
    RPAD(DC.DIRECCION,60,' ') || -- DIRECCION DE CORRESPONDENCIA
    RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO ELECTRONICO
    RPAD(DC.MOVIL,12,' ') || -- CELULAR
    CASE
        WHEN DC.TIPO_ARCHIVO = 'Consumo' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Microcredito' THEN LPAD('490055',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'BajosMontos' THEN LPAD('210052',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Moviaval' THEN LPAD('111399',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Alquila' THEN LPAD('119661',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Resfin' THEN LPAD('280532',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Davivienda' THEN LPAD('440155',6,'0')
        WHEN DC.TIPO_ARCHIVO = 'Avalogic' THEN LPAD('286387',6,'0')		-- ******* PENDIENTE DEFINIR COD SUSCRIPTOR *************
    END
    || -- SUSCRIPTOR DESTINO
    RPAD('0',18,'0') || -- NUMERO DE LA TARJETA
    RPAD('0',1,'0') || -- DETALLE GARANTÍA
    LPAD(' ',18,' ') -- Espacio Reservado de 18 caracteres de longitud
    AS REGISTRO_DETALLE
FROM
    TBL_AVALOGIC DC
--AND DC.CREDITO = '1140545'
--------------------------------------------------------------------------------
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO
SELECT
    LPAD('Z',18,'Z') || -- IDENTIFICADOR
    TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') || -- FECHA PROCESO (último día mes anterior)
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS
    --LPAD(COUNT(DC.CREDITO),8,'0') || -- SUMATORIA DE NOVEDADES
    LPAD(SUM(
        CASE
            WHEN DC.SALDOK <= 0 THEN LPAD('05',2,'0')
                -- 05 CREDITOS CANCELADOS -> SI ESTADO ES CANCELADO 
            -------------------- ---------------------------------------------------
            WHEN DC.ULT_CUOTA = 1 THEN  LPAD(01,2,'0') -- ULTIMA CUOTA AL DIA
            -------------------- ---------------------------------------------------
            WHEN DC.DIASMORA < 30 THEN LPAD(01,2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS
            WHEN DC.DIASMORA < 60 THEN LPAD(06,2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
            WHEN DC.DIASMORA < 90 THEN LPAD(07,2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
            WHEN DC.DIASMORA < 120 THEN LPAD(08,2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
            WHEN DC.DIASMORA >= 120 THEN LPAD(09,2,'0') -- 09 MORA DE 120 DIAS O MAS -> MORA MAYOR O IGUAL A 120 DIAS
        END),8,'0') ||
    LPAD('0',758,'0') -- Espacio Reservado de 758 caracteres de longitud
    AS CONTROL_ARCHIVO
FROM
    TBL_AVALOGIC DC
--------------------------------------------------------------------------------
) MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN 'H' THEN 1
        WHEN 'Z' THEN 3
        ELSE 2
        END
    ,SUBSTR(REGISTRO_CONTROL,13,18)
	
-- reporte2 CIF
------------------------- MAESTRO AVALOGIC CIFIN TXT ------------------------------
---por defecto menos 1
--------------------------------------------------------------------------------
---ORIGINAL
SELECT
*
FROM
(
-- REGISTRO E CONTROL
SELECT DISTINCT
	LPAD(1,1,0)|| --Tipo registro
	LPAD(12,2,0)|| --Codigo paquete
	'159'|| --tipo de entidad 
	'311'|| --- codigo de entidad avalogic
	LPAD(' ',10,' ')|| --- reservado
	LPAD(1,2,0)||--Tipo de reporte
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD') -- FECHA CORTE (ULLTIMO DÍA DEL MES ANTERIOR) (DEFAULT: SYSDATE -uno)
	
	AS REGISTRO_CONTROL
	
FROM 
    TBL_AVALOGIC DC
----aqui empieza el reporte	
UNION
select
	LPAD(2,1,0)|| --Tipo registro
	CASE
            WHEN DC.TIPO_IDENT = '1' -- CC: Cédula de Ciudadanía
            THEN '01'
            WHEN DC.TIPO_IDENT = '2' -- NIT: NIT
            THEN '02'
            WHEN DC.TIPO_IDENT IN ('4') -- CE: Cédula de extranjería
            THEN '03'
            WHEN DC.TIPO_IDENT IN ('7') -- TI: Tarjeta de identidad
            THEN '04'
            WHEN DC.TIPO_IDENT IN ('5') -- PASA: Pasaporte
            THEN '05'
            WHEN DC.TIPO_IDENT IN ('6') -- ppt
            THEN '13'       
            ELSE '00'
	END || --TIPO DE IDENTIFICACION
	LPAD(DC.CEDULA,15,'0') || -- NUMERO DE IDENTIFICACION
	RPAD(UPPER(DC.NOMBRE),60,' ') || -- NOMBRE COMPLETO (MAYÚS)
	LPAD(' ',2,' ')||--reservado
	TO_CHAR(DC.FECHA_VENC, 'YYYYMMDD') || -- FECHA LIMITE DE PAGO
	LPAD(' ',2,' ')|| --ESPACIOS DEL NUMERO DEL CREDITO
 --   LPAD(DC.CREDITO,18,'0') || -- NÚMERO DE CUENTA U OBLIGACION
  CASE 
    WHEN tmp.credito is not null 
    then LPAD(DC.CREDITO,18,' ') 
    else  LPAD(DC.CREDITO,18,'0') 
  END ||
	LPAD(1,6,0)|| ---sucursal
	CASE 
        WHEN DC.TIPO_DEUDOR = 'TI' THEN LPAD('P',1,'0') 
        WHEN DC.TIPO_DEUDOR = 'CO' THEN LPAD('S',1,'0') 
        ELSE '0'
    END 
    || -- RESPONSABLE O CALIDAD DE DEUDOR
	LPAD(' ',2,' ') ||-- CALIFICACION
	LPAD(' ',2,' ') ||-- SITUACION
    CASE
        WHEN DC.SALDOK <= 0 THEN LPAD('07',2,'0')
        ELSE LPAD('04',2,'0')
    END 
    || -- ESTADO DE LA CUENTA
    CASE
        WHEN DC.DIASMORA < 30 THEN LPAD('01',2,'0') -- 01 AL DIA -> MORA MENOR A 30 DIAS se ajusta a que siempre este en mora
        WHEN DC.DIASMORA < 60 THEN LPAD('01',2,'0') -- 06 MORA DE 30 DIAS -> MORA MENOR A 60 DIAS
        WHEN DC.DIASMORA < 90 THEN LPAD('02',2,'0') -- 07 MORA DE 60 DIAS -> MORA MENOR A 90 DIAS
        WHEN DC.DIASMORA < 120 THEN LPAD('03',2,'0') -- 08 MORA DE 90 DIAS -> MORA MENOR A 120 DIAS
        WHEN DC.DIASMORA < 150 THEN LPAD('04',2,'0') 
        WHEN DC.DIASMORA < 180 THEN LPAD('05',2,'0') 
        WHEN DC.DIASMORA < 210 THEN LPAD('06',2,'0') 
        WHEN DC.DIASMORA < 240 THEN LPAD('07',2,'0') 
        WHEN DC.DIASMORA < 270 THEN LPAD('08',2,'0') 
        WHEN DC.DIASMORA < 300 THEN LPAD('09',2,'0') 
        WHEN DC.DIASMORA < 330 THEN LPAD('10',2,'0') 
        WHEN DC.DIASMORA < 360 THEN LPAD('11',2,'0') 
        WHEN DC.DIASMORA < 540 THEN LPAD('12',2,'0') 
        WHEN DC.DIASMORA < 730 THEN LPAD('13',2,'0') 
        WHEN DC.DIASMORA >= 730 THEN LPAD('14',2,'0') 		
    END 
    || -- edad de mora
	LPAD(' ',2,' ')||-- ANOS MORA OPCIONAL
	TO_CHAR(LAST_DAY (ADD_MONTHS(TRUNC(SYSDATE,'MM'),-1)), 'YYYYMMDD')|| -- FECHA CORTE sysdate menos uno
	TO_CHAR(DC.FECHA_INICIO, 'YYYYMMDD') || -- FECHA DE APERTURA
	LPAD(' ',8,' ')|| --- FECHA TERMINACION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA EXIGIBILIDAD OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA PRESCRIPCION OPCIONAL
	LPAD(' ',8,' ')|| --- FECHA DE PAGO OPCIONAL
	LPAD(' ',2,' ')|| --- MODO EXTINCION OPCIONAL
	LPAD(' ',2,' ')|| --- TIPO DE PAGO OPCIONAL
	LPAD('05',2,'0') || -- PERIODICIDAD DE PAGO (Mensual)
	LPAD(' ',3,' ')|| --- PROBABILIDAD
	LPAD(' ',3,' ')|| --- CUOTAS PAGADAS
	LPAD(' ',3,' ')|| --- CUOTAS PACTADAS
	CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',3,'0')
        
        ELSE LPAD(DC.CUOTAS,3,'0')
    END
    ||  --- CUOTAS EN MORA
	LPAD(CAST(DC.VLRDESEMBOLSO/1000 AS INT),12,'0') || -- VALOR INICIAL (VALOR DESEMBOLSO)
    CASE 
        WHEN DC.SALDOK = 0 THEN LPAD('0',12,'0')
        
        ELSE LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') 
    END
    || -- VALOR MORA (VALOR MORA)	
    LPAD(CAST(DC.SALDOK/1000 AS INT),12,'0') || -- VALOR DEL SALDO
    LPAD(CAST(DC.VALORCUOTA/1000 AS INT),12,'0') || -- VALOR CUOTA MENSUAL
	LPAD(' ',12,' ') || -- VALOR CARGO FIJO
	LPAD('033',3,'0') || -- LINEA DE CREDITO
	LPAD(' ',3,' ') || -- CLAUSULA DE PERMANENCIA
	LPAD('1',3,'0') || -- TIPO DE CONTRATO (CREDITO)
	LPAD(' ',3,' ') || -- ESTADO DE CONTRATO
	LPAD(' ',2,' ') || -- TERMINO DE VIGENCIA DE CONTRATO
	LPAD(' ',3,' ') || -- NUMERO MESES CONTRATO
	LPAD(' ',3,' ') || -- NATURALEZA JURIDICA
	LPAD(' ',2,' ') || -- MODALIDAD DE CREDITO
	LPAD(' ',2,' ') || -- TIPO MONEDA
	LPAD(' ',2,' ') || -- TIPO DE GARANTIA
	LPAD(' ',12,' ') || -- VALOR GARANTIA
	LPAD('02',2,'0') || -- OBLIGACION REESTRUCTURADA
	LPAD(' ',2,' ') || -- NATURALEZA
	LPAD(' ',3,' ') || -- NUMERO DE REESTRUCTURACIONES
	LPAD(' ',2,' ') || -- CLASE DE TARJETA
	LPAD(' ',4,' ') || -- NUMERO DE CHEQUES DEVUELTOS
	LPAD(' ',2,' ') || -- CATEGORIA SERVICIOS
	LPAD(' ',2,' ') || -- PLAZO
	LPAD(' ',6,' ') || -- DIAS CARTERA
	LPAD(' ',2,' ') || -- TIPO DE CUENTA
	LPAD(' ',12,' ') || -- CUPO SOBREGIRO
	LPAD(' ',3,' ') || -- DIAS AUTORIZADOS
	RPAD(DC.DIRECCION,60,' ') || -- CIUDAD DE RESIDENCIA O CIUDAD COMERCIAL
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDAD CASA
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',60,' ') || -- EMPRESA
	LPAD(' ',60,' ') || -- DIRECCION
	LPAD(' ',20,' ') || -- TELEFONO
	LPAD(' ',6,' ') || -- COD CIUDADD (9)
	LPAD(' ',20,' ') || -- CIUDAD
	LPAD(' ',3,' ') || -- COD DEPARTAMENTO
	LPAD(' ',20,' ') || -- DEPARTAMENTO
	LPAD(' ',8,' ') || -- FECHA INCIO
	LPAD(' ',8,' ') || -- FECHA TERMINACION
	LPAD(' ',2,' ') || -- NUM RENOV CDT
	LPAD(' ',2,' ') || -- CTA
	LPAD(' ',2,' ') || -- TIPO IDENTI ORD
	LPAD(' ',14,' ') || -- NUM IDENT ORIGINARIA
	LPAD(' ',3,' ') || -- TIPO ENTIDAD ORIG
	LPAD(' ',3,' ') || -- COD ENT ORIGINARIA
	LPAD(' ',2,' ') || -- TIPO FIDEICOMISO
	LPAD(' ',12,' ') || -- NUM FIDEICOMISO
	LPAD(' ',60,' ') || -- NOMBRE FIDEICOMISO
	LPAD(' ',4,' ') || -- TIPO DEUDA CARTERA
	LPAD(' ',4,' ') || -- TIPO POLIZA
	LPAD(' ',6,' ') || -- CODIGO RAMO
	LPAD(' ',20,' ') || -- NUM REAL Tarjeta
	RPAD(DC.CORREO_ELECTRONICO,60,' ') || -- CORREO
	RPAD(DC.MOVIL,60,' ') || -- CELULAR
	LPAD(' ',12,' ')  -- VALOR REAL PAGADO
FROM
    TBL_AVALOGIC DC
    LEFT JOIN ACTUARIA.TEMP_CREDITOS_CONESPACIOS@DBLINKACTUARIA tmp on tmp.credito = dc.credito
UNION
--------------------------------------------------------------------------------
-- REGISTRO DE CONTROL DE ARCHIVO - PIE DE PAGINA
SELECT
    LPAD('9',1,'0') || -- TIPO REGISTRO
    LPAD((COUNT(DC.CREDITO)+2),8,'0') || -- NUMERO DE REGISTROS CON ENCABEZADO Y PIE DE PAGINA
    LPAD(COUNT(DC.CREDITO),8,'0') || -- NUMERO DE REGISTROS
	LPAD('0',8,'0') || -- NUMERO DE REGISTROS TIPO 3
	LPAD('0',8,'0')  -- NUMERO DE REGISTROS TIPO 4
    AS CONTROL_ARCHIVO
FROM
    TBL_AVALOGIC DC
) 
MASTER
ORDER BY 
    CASE SUBSTR(REGISTRO_CONTROL,1,1)
        WHEN '1' THEN 1
        WHEN '9' THEN 3
        ELSE 2
        END