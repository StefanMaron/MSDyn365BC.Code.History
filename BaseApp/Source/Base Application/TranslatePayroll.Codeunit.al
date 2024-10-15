codeunit 17499 "Translate Payroll"
{

    trigger OnRun()
    begin
    end;

    var
        TestMode: Boolean;
        F_ADVANCERATEDAYSTxt: Label 'ADVANCE RATE DAYS';
        F_ADVANCERATEHOURSTxt: Label 'ADVANCE RATE HOURS';
        F_AMOUNTYTDTxt: Label 'AMOUNT YTD';
        F_BALANCETODATETxt: Label 'BALANCE TO DATE';
        F_CALDAYSACTIONTxt: Label 'CAL DAYS ACTION';
        F_CALDAYSPERIODTxt: Label 'CAL DAYS PERIOD';
        F_CALDAYSWAGEPERIODTxt: Label 'CAL DAYS WAGE PERIOD';
        F_CALDAYSPERIODBYRATETxt: Label 'CAL DAYS PERIOD BY RATE';
        F_CALHOURSPERIODBYRATETxt: Label 'CAL HOURS PERIOD BY RATE';
        F_CALWORKDAYSACTIONTxt: Label 'CAL WORK DAYS ACTION';
        F_CALWORKDAYSPERIODTxt: Label 'CAL WORK DAYS PERIOD';
        F_CALWORKDAYSYEARTxt: Label 'CAL WORK DAYS YEAR';
        F_CALWORKHOURSPERIODTxt: Label 'CAL WORK HOURS PERIOD';
        F_CALWORKHOURSYEARTxt: Label 'CAL WORK HOURS YEAR';
        F_CALCBASEAMOUNTTxt: Label 'CALC BASE AMOUNT';
        F_CALCBASEBALANCETxt: Label 'CALC BASE BALANCE';
        F_DEDUCTIONAMOUNTBYQTYTxt: Label 'DEDUCTION AMOUNT BY QTY';
        F_EARNINGSYTDTxt: Label 'EARNINGS YTD';
        F_EMPLOYEEBASESALARYTxt: Label 'EMPLOYEE BASE SALARY';
        F_EMPLOYEEEXTRASALARYTxt: Label 'EMPLOYEE EXTRA SALARY';
        F_EXTRAPAYBYHOURSTxt: Label 'EXTRA PAY BY HOURS';
        F_GETAEDATATxt: Label 'GET AE DATA';
        F_GETCOEFFICIENTTxt: Label 'GET COEFFICIENT';
        F_GETDEDUCTIONTxt: Label 'GET DEDUCTION';
        F_GETENTRYAMOUNTTxt: Label 'GET ENTRY AMOUNT';
        F_GETENTRYQTYTxt: Label 'GET ENTRY QTY';
        F_GETMAXAMOUNTTxt: Label 'GET MAX AMOUNT';
        F_GETMINAMOUNTTxt: Label 'GET MIN AMOUNT';
        F_GETSERVICEYEARSTxt: Label 'GET SERVICE YEARS';
        F_GETSTARTBALANCETxt: Label 'GET START BALANCE';
        F_GETTAXRATEAMTTxt: Label 'GET TAX RATE AMT';
        F_INCOMEDISCOUNTTxt: Label 'INCOME DISCOUNT';
        F_INCOMETAXAMOUNTYTDTxt: Label 'INCOME TAX AMOUNT YTD';
        F_LABORCONTRACTTYPETxt: Label 'LABOR CONTRACT TYPE';
        F_MAXDAILYAEPAYTxt: Label 'MAX DAILY AE PAY';
        F_MAXMONTHLYAEPAYTxt: Label 'MAX MONTHLY AE PAY';
        F_MONTHLYRATEDAYSTxt: Label 'MONTHLY RATE DAYS';
        F_MONTHLYRATEHOURSTxt: Label 'MONTHLY RATE HOURS';
        F_NDFLAMOUNTYTDTxt: Label 'NDFL AMOUNT YTD';
        F_NDFLTAXABLEYTDTxt: Label 'NDFL TAXABLE YTD';
        F_PAIDFROMCASHDESKTxt: Label 'PAID FROM CASHDESK';
        F_PREVDEDUCTIONAMOUNTTxt: Label 'PREV DEDUCTION AMOUNT';
        F_PREVINCOMEAMOUNTTxt: Label 'PREV INCOME AMOUNT';
        F_PREVINCOMETAXACCRUEDTxt: Label 'PREV INCOME TAX ACCRUED';
        F_PREVINCOMETAXPAIDTxt: Label 'PREV INCOME TAX PAID';
        F_PREVPERIODRATETxt: Label 'PREV PERIOD RATE';
        F_PROPERTYDEDUCTIONTxt: Label 'PROPERTY DEDUCTION';
        F_TIMESHEETDAYSTxt: Label 'TIME SHEET DAYS';
        F_TIMESHEETHOURSTxt: Label 'TIME SHEET HOURS';
        EC_ADVANCEWORKEDDAYSTxt: Label 'ADVANCE WORKED DAYS';
        EC_ADVANCEWORKEDHOURSTxt: Label 'ADVANCE WORKED HOURS';
        EC_AMOUNTDUEPAYTxt: Label 'AMOUNT DUE PAY';
        EC_AUTHORPAYTxt: Label 'AUTHOR PAY';
        EC_BENEFITCHILDBIRTHTxt: Label 'BENEFIT CHILD BIRTH';
        EC_BENEFITEARLYPREGTxt: Label 'BENEFIT EARLY PREG';
        EC_BENEFITFUNERALTxt: Label 'BENEFIT FUNERAL';
        EC_BENEFITORDERTxt: Label 'BENEFIT ORDER';
        EC_BONUSAMOUNTTxt: Label 'BONUS AMOUNT';
        EC_BONUSANNUALAMTTxt: Label 'BONUS ANNUAL AMT';
        EC_BONUSANNUALPERCTxt: Label 'BONUS ANNUAL PERC';
        EC_BONUSMONTHLYAMTTxt: Label 'BONUS MONTHLY AMT';
        EC_BONUSMONTHLYPERCTxt: Label 'BONUS MONTHLY PERC';
        EC_BONUSMONTHLYPERCLMTxt: Label 'BONUS MONTHLY PERC LM';
        EC_BONUSQUARTERLYAMTTxt: Label 'BONUS QUARTERLY AMT';
        EC_BONUSQUARTERLYPERCTxt: Label 'BONUS QUARTERLY PERC';
        EC_BUSINESSTRAVELTxt: Label 'BUSINESS TRAVEL';
        EC_CONTRACTSERVTxt: Label 'CONTRACT SERV';
        EC_CONTRACTWORKTxt: Label 'CONTRACT WORK';
        EC_DEDUCTMEALSTxt: Label 'DEDUCT MEALS';
        EC_DEDUCTPROPERTY313Txt: Label 'DEDUCT PROPERTY 313';
        EC_DEDUCTTxt: Label 'DEDUCT';
        EC_DISMISSALCOMP3MTxt: Label 'DISMISSAL COMP 3M';
        EC_DISMISSALPAYAMOUNTTxt: Label 'DISMISSAL PAY AMOUNT';
        EC_DISMISSALPAYDAYSTxt: Label 'DISMISSAL PAY DAYS';
        EC_DIVIDENDSTxt: Label 'DIVIDENDS';
        EC_EXECACTAMTTxt: Label 'EXEC ACT AMT';
        EC_EXECACTTRANSFAMTTxt: Label 'EXEC ACT TRANSF AMT';
        EC_EXECACTTRANSFPERTxt: Label 'EXEC ACT TRANSF PER';
        EC_EXECACTPERTxt: Label 'EXEC ACT PER';
        EC_EXTRAPAYAMTTxt: Label 'EXTRA PAY AMT';
        EC_EXTRAPAYDAYTxt: Label 'EXTRA PAY DAY';
        EC_EXTRAPAYDAYPERTxt: Label 'EXTRA PAY DAY PER';
        EC_EXTRAPAYHOLIDAYAMTTxt: Label 'EXTRA PAY HOLIDAY AMT';
        EC_EXTRAPAYHOLIDAYSTxt: Label 'EXTRA PAY HOLIDAYS';
        EC_EXTRAPAYHOURSTxt: Label 'EXTRA PAY HOURS';
        EC_EXTRAPAYHOURSPERTxt: Label 'EXTRA PAY HOURS PER';
        EC_EXTRAPAYNIGHTTxt: Label 'EXTRA PAY NIGHT';
        EC_EXTRAPAYNIGHTAMTTxt: Label 'EXTRA PAY NIGHT AMT';
        EC_EXTRAPAYNOWORKAMTTxt: Label 'EXTRA PAY NO WORK AMT';
        EC_EXTRAPAYNOWORKDSTxt: Label 'EXTRA PAY NO WORK DS';
        EC_EXTRAPAYNOWORKHSTxt: Label 'EXTRA PAY NO WORK HS';
        EC_EXTRAPAYOVERTAMTTxt: Label 'EXTRA PAY OVERT AMT';
        EC_EXTRAPAYOVERT15Txt: Label 'EXTRA PAY OVERT15';
        EC_EXTRAPAYOVERT2Txt: Label 'EXTRA PAY OVERT 2';
        EC_GIFTSTxt: Label 'GIFTS';
        EC_INCOMETAXDIVIDTxt: Label 'INCOME TAX DIVID';
        EC_INCOMETAX13PERTxt: Label 'INCOME TAX 13%';
        EC_INCOMETAX30PERTxt: Label 'INCOME TAX 30%';
        EC_INCOMETAX35PERTxt: Label 'INCOME TAX 35%';
        EC_INTERPERIODPAYTxt: Label 'INTER PERIOD PAY';
        EC_LOANTxt: Label 'LOAN';
        EC_LOANBENEFITTxt: Label 'LOAN BENEFIT';
        EC_LOANPAYTxt: Label 'LOAN PAY';
        EC_OTHERINCOMETAXABLETxt: Label 'OTHER INCOME TAXABLE';
        EC_P4TOTALWAGESTxt: Label 'P-4 TOTAL WAGES';
        EC_P4TOTALBENEFITSTxt: Label 'P-4 TOTAL BENEFITS';
        EC_PAYAETIMESHEETTxt: Label 'PAY AE TIMESHEET';
        EC_PAYAVGEARNINGSTxt: Label 'PAY AVG EARNINGS';
        EC_PAYCONTRVMTxt: Label 'PAY CONTR VM';
        EC_PAYGOVERNDUTIESTxt: Label 'PAY GOVERN DUTIES';
        EC_PAYMEALSTxt: Label 'PAY MEALS';
        EC_PAYMEALSNATTxt: Label 'PAY MEALS NAT';
        EC_PAYSLAMTTxt: Label 'PAY SL AMT';
        EC_PAYSLAMTOWNTxt: Label 'PAY SL AMT OWN';
        EC_PAYSLCHILDAMTTxt: Label 'PAY SL CHILD AMT';
        EC_PAYSLCHILDDAYSTxt: Label 'PAY SL CHILD DAYS';
        EC_PAYSLDAYSTxt: Label 'PAY SL DAYS';
        EC_PAYSLHOMEAMTTxt: Label 'PAY SL HOME AMT';
        EC_PAYSLHOMEDAYSTxt: Label 'PAY SL HOME DAYS';
        EC_PAYSLINJURYAMTTxt: Label 'PAY SL INJURY AMT';
        EC_PAYSLINJURYDAYSTxt: Label 'PAY SL INJURY DAYS';
        EC_PAYSLPREGAMTTxt: Label 'PAY SL PREG AMT';
        EC_PAYSLPREGDAYSTxt: Label 'PAY SL PREG DAYS';
        EC_PENALTYTxt: Label 'PENALTY';
        EC_PERSONALAUTOTxt: Label 'PERSONAL AUTO';
        EC_PLANNEDADVANCETxt: Label 'PLANNED ADVANCE';
        EC_PROFUNIONPAYTxt: Label 'PROF UNION PAY';
        EC_SALARYAMOUNTTxt: Label 'SALARY AMOUNT';
        EC_SALARYBASETxt: Label 'SALARY BASE';
        EC_SALARYDAYTxt: Label 'SALARY DAY';
        EC_SALARYDIFFAMTTxt: Label 'SALARY DIFF AMT';
        EC_SALARYDIFFDAYTxt: Label 'SALARY DIFF DAY';
        EC_SALARYDIFFHOURTxt: Label 'SALARY DIFF HOUR';
        EC_SALARYHOURTxt: Label 'SALARY HOUR';
        EC_SALARYTARIFFTxt: Label 'SALARY TARIFF';
        EC_STARTBALANCETxt: Label 'START BALANCE';
        EC_TAXFEDFMITxt: Label 'TAX FED FMI';
        EC_TAXFEDFMIDISTxt: Label 'TAX FED FMI DIS';
        EC_TAXFSITxt: Label 'TAX FSI';
        EC_TAXFSIDISTxt: Label 'TAX FSI DIS';
        EC_TAXFSIINJTxt: Label 'TAX FSI INJ';
        EC_TAXFSIINJDISTxt: Label 'TAX FSI INJ DIS';
        EC_TAXPFINSTxt: Label 'TAX PF INS';
        EC_TAXPFINSDISTxt: Label 'TAX PF INS DIS';
        EC_TAXPFSAVTxt: Label 'TAX PF SAV';
        EC_TAXREPPFINSLIMITTxt: Label 'TAX REP PFINS LIMIT';
        EC_TAXREPPFMIBASETxt: Label 'TAX REP PFMI BASE';
        EC_TAXREPPFMINOTAXTxt: Label 'TAX REP PFMI NO TAX';
        EC_TAXREPPFMIOVERTxt: Label 'TAX REP PFMI OVER';
        EC_TAXREPFSIBASETxt: Label 'TAX REP FSI BASE';
        EC_TAXREPFSINOTAXTxt: Label 'TAX REP FSI NO TAX';
        EC_TAXREPFSIOVERTxt: Label 'TAX REP FSI OVER';
        EC_TAXREPSPECIAL1Txt: Label 'TAX REP SPECIAL 1';
        EC_TAXREPSPECIAL2Txt: Label 'TAX REP SPECIAL 2';
        EC_TAXTERFMITxt: Label 'TAX TER FMI';
        EC_TOTALBONUSTxt: Label 'TOTAL BONUS';
        EC_TOTALDEDUCTIONTxt: Label 'TOTAL DEDUCTION';
        EC_TOTALFEDFMITxt: Label 'TOTAL FED FMI';
        EC_TOTALFSITxt: Label 'TOTAL FSI';
        EC_TOTALFSIINJURYTxt: Label 'TOTAL FSI INJURY';
        EC_TOTALINCOMETAXTxt: Label 'TOTAL INCOME TAX';
        EC_TOTALPFACCUMTxt: Label 'TOTAL PF ACCUM';
        EC_TOTALPFINSURTxt: Label 'TOTAL PF INSUR';
        EC_TOTALTAXDEDUCTIONTxt: Label 'TOTAL TAX DEDUCTION';
        EC_TOTALTERFMITxt: Label 'TOTAL TER FMI';
        EC_TOTALWAGETxt: Label 'TOTAL WAGE';
        EC_VACCHERNOBYLTxt: Label 'VAC CHERNOBYL';
        EC_VACCHILD3DAYSTxt: Label 'VAC CHILD 3 DAYS';
        EC_VACCHILD115DAYSTxt: Label 'VAC CHILD 1 15 DAYS';
        EC_VACCHILD215DAYSTxt: Label 'VAC CHILD 2 15 DAYS';
        EC_VACCHILD315DAYSTxt: Label 'VAC CHILD 3 15 DAYS';
        EC_VACCOMPENSTxt: Label 'VAC COMPENS';
        EC_VACCOMPENSAMTTxt: Label 'VAC COMPENS AMT';
        EC_VACEDUCATIONTxt: Label 'VAC EDUCATION';
        EC_VACEDUCATIONAMTTxt: Label 'VAC EDUCATION AMT';
        EC_VACREGULARTxt: Label 'VAC REGULAR';
        EC_VACREGULARAMTTxt: Label 'VAC REGULAR AMT';
        EC_VACWOPAYMENTTxt: Label 'VAC WO PAYMENT';
        EG_ADVANCEPAYTxt: Label 'ADVANCE PAY';
        EG_BASESALARYTxt: Label 'BASE SALARY';
        EG_BONUSTxt: Label 'BONUS';
        EG_DEDUCTIONTxt: Label 'DEDUCTION';
        EG_DIVIDENDSTxt: Label 'DIVIDENDS';
        EG_EXTRAPAYHOLIDAYTxt: Label 'EXTRA PAY HOLIDAY';
        EG_EXTRAPAYNIGHTTxt: Label 'EXTRA PAY NIGHT';
        EG_EXTRAPAYNOWORKTxt: Label 'EXTRA PAY NO WORK';
        EG_EXTRAPAYOTHERTxt: Label 'EXTRA PAY OTHER';
        EG_EXTRAPAYOVERTTxt: Label 'EXTRA PAY OVERT';
        EG_FUNDSTxt: Label 'FUNDS';
        EG_INCOMETAXTxt: Label 'INCOME TAX';
        EG_LOANBENEFITTxt: Label 'LOAN BENEFIT';
        EG_OTHERTxt: Label 'OTHER';
        EG_REPORTINGTxt: Label 'REPORTING';
        EG_TAXDEDUCTIONTxt: Label 'TAX DEDUCTION';
        EG_SALARYPAYTxt: Label 'SALARY PAY';
        EG_SICKLEAVEPAYTxt: Label 'SICK LEAVE PAY';
        EG_STARTBALANCETxt: Label 'START BALANCE';
        EG_VACATIONTxt: Label 'VACATION';
        EGN_AdvancePayTxt: Label 'AdvancePay';
        EGN_BaseSalaryTxt: Label 'BaseSalary';
        EGN_BonusesTxt: Label 'Bonuses';
        EGN_DeductionsTxt: Label 'Deductions';
        EGN_DividendsTxt: Label 'Dividends';
        EGN_ExtrapayforholidayworkTxt: Label 'Extra pay for holiday work';
        EGN_ExtrapayfornightworkTxt: Label 'Extra pay for night work';
        EGN_ExtrapayfornoworkTxt: Label 'Extra pay for no work';
        EGN_ExtrapayforovertimeTxt: Label 'Extra pay for overtime';
        EGN_OtherextrapaysTxt: Label 'Other extra pays';
        EGN_FundsTxt: Label 'Funds';
        EGN_IncomeTaxTxt: Label 'Income Tax';
        EGN_LoanBenefitTxt: Label 'Loan Benefit';
        EGN_OtherTxt: Label 'Other';
        EGN_ReportingelementsTxt: Label 'Reporting elements';
        EGN_SalarypaymentsTxt: Label 'Salary payments';
        EGN_SickleavepayTxt: Label 'Sick leave pay';
        EGN_StartingbalanceTxt: Label 'Starting balance';
        EGN_TaxdeductionsTxt: Label 'Tax deductions';
        EGN_VacationsTxt: Label 'Vacations';
        PGC_ADVANTAGETxt: Label 'ADVANTAGE';
        PGC_BENEFITTxt: Label 'BENEFIT';
        PGC_ALIMONYTxt: Label 'ALIMONY';
        PGC_BENEFIT69ALLTxt: Label 'BENEFIT 69 ALL';
        PGC_BENEFIT69INJTxt: Label 'BENEFIT 69 INJ';
        PGC_BENEFIT69NOATxt: Label 'BENEFIT 69 NOA';
        PGC_CONTRACTTxt: Label 'CONTRACT';
        PGC_DAMAGETxt: Label 'DAMAGE';
        PGC_DEPONENTTxt: Label 'DEPONENT';
        PGC_DUEPAYTxt: Label 'DUE PAY';
        PGC_EMPLRETURNTxt: Label 'EMPL RETURNT';
        PGC_EMPLSETTLETxt: Label 'EMPL SETTLE';
        PGC_ENDBALANCETxt: Label 'END BALANCE';
        PGC_FEDFMI20Txt: Label 'FED FMI-20';
        PGC_FEDFMI26Txt: Label 'FED FMI-26';
        PGC_FEDFMI44Txt: Label 'FED FMI-44';
        PGC_FPVACATION20Txt: Label 'FP VACATION-20';
        PGC_FPVACATION26Txt: Label 'FP VACATION-26';
        PGC_FPVACATION44Txt: Label 'FP VACATION-44';
        PGC_FSIINJ20Txt: Label 'FSI INJ-20';
        PGC_FSIINJ26Txt: Label 'FSI INJ-26';
        PGC_FSIINJ44Txt: Label 'FSI INJ-44';
        PGC_FSI20Txt: Label 'FSI-20';
        PGC_FSI26Txt: Label 'FSI-26';
        PGC_FSI44Txt: Label 'FSI-44';
        PGC_INCOMETAXTxt: Label 'INCOME TAX';
        PGC_INTERMPAYTxt: Label 'INTERM PAY';
        PGC_LOANPAYTxt: Label 'LOAN PAY';
        PGC_MEALSTxt: Label 'MEALS';
        PGC_PAYR20Txt: Label 'PAYR-20';
        PGC_PAYR26Txt: Label 'PAYR-26';
        PGC_PAYR44Txt: Label 'PAYR-44';
        PGC_PENALTYTxt: Label 'PENALTY';
        PGC_PFINS20Txt: Label 'PFINS-20';
        PGC_PFINS26Txt: Label 'PFINS-26';
        PGC_PFINS44Txt: Label 'PFINS-44';
        PGC_PFSAV20Txt: Label 'PFSAV-20';
        PGC_PFSAV26Txt: Label 'PFSAV-26';
        PGC_PFSAV44Txt: Label 'PFSAV-44';
        PGC_PF14PER20Txt: Label 'PF14%-20';
        PGC_PF14PER26Txt: Label 'PF14%-26';
        PGC_PF14PER44Txt: Label 'PF14%-44';
        PGC_PROFUNIONPAYTxt: Label 'PROF UNION PAY';
        PGC_PROFITPAYTxt: Label 'PROFIT PAY';
        PGC_STARTBALANCETxt: Label 'START BALANCE';
        PGC_TERFMI20Txt: Label 'TERFMI-20';
        PGC_TERFMI26Txt: Label 'TERFMI-26';
        PGC_TERFMI44Txt: Label 'TERFMI-44';
        GC_ADVANCETxt: Label 'ADVANCE';
        GC_DISABLED20Txt: Label 'DISABLED20';
        GC_INTERBONUSTxt: Label 'INTERBONUS';
        GC_INTERPAYMTxt: Label 'INTERPAYM';
        GC_ABSINTPAYTxt: Label 'ABSINTPAY';
        GC_PAYR20Txt: Label 'PAYR-20';
        GC_PAYR26Txt: Label 'PAYR-26';
        GC_PAYR44Txt: Label 'PAYR-44';
        GN_PayrollAdvanceTxt: Label 'Payroll Advance';
        GN_Disabledonaccount20Txt: Label 'Disabled on account 20';
        GN_InterimBonusTxt: Label 'Interim Bonus';
        GN_InterimPaymentTxt: Label 'Interim Payment';
        GN_SalaryandTaxeson20accountTxt: Label 'Salary and Taxes on 20 account';
        GN_SalaryandTaxeson26accountTxt: Label 'Salary and Taxes on 26 account';
        GN_SalaryandTaxeson44accountTxt: Label 'Salary and Taxes on 44 account';
        TC_ADVANTAGETxt: Label 'ADVANTAGE';
        TC_ALIMONYTxt: Label 'ALIMONY';
        TC_AMOUNTDUEPAYTxt: Label 'AMOUNT DUE PAY';
        TC_AUTHORINCOMETxt: Label 'AUTHOR INCOME';
        TC_AVGEARNINGPAYTxt: Label 'AVG EARNING PAY';
        TC_BENEFITORDERTxt: Label 'BENEFIT ORDER';
        TC_BENEFITSTxt: Label 'BENEFITS';
        TC_BONUSTxt: Label 'BONUS';
        TC_BUSINESSTRAVELTxt: Label 'BUSINESS TRAVEL';
        TC_CHERNOBYLPAYTxt: Label 'CHERNOBYL PAY';
        TC_DEDUCTCHILDRENTxt: Label 'DEDUCT CHILDREN';
        TC_DEDUCTMEALSTxt: Label 'DEDUCT MEALS';
        TC_DEDUCTOTHERSTxt: Label 'DEDUCT OTHERS';
        TC_DEDUCTPROPERTYTxt: Label 'DEDUCT PROPERTY';
        TC_DEDUCTSTANDARDTxt: Label 'DEDUCT STANDARD';
        TC_DEDUCT501503Txt: Label 'DEDUCT 501 503';
        TC_DEPONENTTxt: Label 'DEPONENT';
        TC_DISMISSALPAYTxt: Label 'DISMISSAL PAY';
        TC_DIVIDENDSTxt: Label 'DIVIDENDS';
        TC_EXECUTIVEACTTxt: Label 'EXECUTIVE ACT';
        TC_EXECUTIVEACTALIMTxt: Label 'EXECUTIVE ACT ALIM';
        TC_EXTRAPAYAMOUNTTxt: Label 'EXTRA PAY AMOUNT';
        TC_EXTRAPAYNOWORKTxt: Label 'EXTRA PAY NO WORK';
        TC_EXTRAPAYOTHERTxt: Label 'EXTRA PAY OTHER';
        TC_EXTRAPAYOVERTIMETxt: Label 'EXTRA PAY OVERTIME';
        TC_GIFTSTxt: Label 'GIFTS';
        TC_INCOMETAXDIVIDTxt: Label 'INCOME TAX DIVID';
        TC_INCOMETAX13PERTxt: Label 'INCOME TAX 13%';
        TC_INCOMETAX35PERTxt: Label 'INCOME TAX 35%';
        TC_INJURYTAXDISABL20Txt: Label 'INJURY TAX DISABL-20';
        TC_INJURYTAX20Txt: Label 'INJURY TAX-20';
        TC_INJURYTAX26Txt: Label 'INJURY TAX-26';
        TC_INJURYTAX44Txt: Label 'INJURY TAX-44';
        TC_INTPERIODPAYTxt: Label 'INT PERIOD PAY';
        TC_LOANPAYTxt: Label 'LOAN PAY';
        TC_LOANTxt: Label 'LOAN';
        TC_NONBUDGETTAX20Txt: Label 'NON BUDGET TAX-20';
        TC_NONBUDGETTAX26Txt: Label 'NON BUDGET TAX-26';
        TC_NONBUDGETTAX44Txt: Label 'NON BUDGET TAX-44';
        TC_NONBUDGETREPORTTxt: Label 'NON BUDGET REPORT';
        TC_OTHERINCOMETxt: Label 'OTHER INCOME';
        TC_PENALTYTxt: Label 'PENALTY';
        TC_PERSONALAUTOTxt: Label 'PERSONAL AUTO';
        TC_PLANNEDADVANCETxt: Label 'PLANNED ADVANCE';
        TC_PROFUNIONPAYTxt: Label 'PROF UNION PAY';
        TC_RETURNAMOUNTSTxt: Label 'RETURN AMOUNTS';
        TC_SALARYTxt: Label 'SALARY';
        TC_SALARYDIFFERENCETxt: Label 'SALARY DIFFERENCE';
        TC_SHORTAGETxt: Label 'SHORTAGE';
        TC_SICKLISTPAYTxt: Label 'SICK LIST PAY';
        TC_SICKLISTPAYCHILDTxt: Label 'SICK LIST PAY CHILD';
        TC_SICKLISTPAYHOMETxt: Label 'SICK LIST PAY HOME';
        TC_SICKLISTPAYINJURYTxt: Label 'SICK LIST PAY INJURY';
        TC_SICKLISTPAYPREGTxt: Label 'SICK LIST PAY PREG';
        TC_VACATIONCHERNOBYLTxt: Label 'VACATION CHERNOBYL';
        TC_VACATIONCHILDCARETxt: Label 'VACATION CHILDCARE';
        TC_VACATIONCOMPENSATTxt: Label 'VACATION COMPENSAT';
        TC_VACATIONEDUCATIONTxt: Label 'VACATION EDUCATION';
        TC_VACATIONREGULARTxt: Label 'VACATION REGULAR';
        TN_AdvantagesTxt: Label 'Advantages';
        TN_AmountduepayTxt: Label 'Amount due pay';
        TN_AuthorincomeTxt: Label 'Author income';
        TN_PaybyaverageearningsTxt: Label 'Pay by average earnings';
        TN_BenefitordersTxt: Label 'Benefit orders';
        TN_BenefitsTxt: Label 'Benefits';
        TN_BonusTxt: Label 'Bonus';
        TN_BusinesstravelTxt: Label 'Business travel';
        TN_ChildtaxdeductionsTxt: Label 'Child tax deductions';
        TN_MealdeductionsTxt: Label 'Meal deductions';
        TN_PropertytaxdeductionsTxt: Label 'Property tax deductions';
        TN_StandardtaxdeductionsTxt: Label 'Standard tax deductions';
        TN_501503taxdeductionsTxt: Label 'Deductions 501 503';
        TN_DismissalpayTxt: Label 'Dismissal pay';
        TN_DividendsTxt: Label 'Dividends';
        TN_ExecutiveactdeductionsTxt: Label 'Executive act deductions';
        TN_ExtrapayamountsTxt: Label 'Extrapayamounts';
        TN_NoworkextrapaysTxt: Label 'No work extra pays';
        TN_OtherextrapaysTxt: Label 'Other extra pays';
        TN_OverttimeextrapaysTxt: Label 'Overtime extra pays';
        TN_GiftsTxt: Label 'Gifts';
        TN_IncometaxfordividendsTxt: Label 'Income tax for dividends';
        TN_Incometax13PERTxt: Label 'Income tax 13%';
        TN_Incometax35PERTxt: Label 'Income tax 35%';
        TN_Injurytaxfordisabledonaccount20Txt: Label 'Injury tax for disabled on account 20';
        TN_Injurytaxonaccount20Txt: Label 'Injury tax on account 20';
        TN_Injurytaxonaccount26Txt: Label 'Injury tax on account 26';
        TN_Injurytaxonaccount44Txt: Label 'Injury tax on account 44';
        TN_LoanTxt: Label 'Loan';
        TN_LoanpayTxt: Label 'Loanpay';
        TN_Nonbudgettaxonaccount20Txt: Label 'Non budget tax on account 20';
        TN_Nonbudgettaxonaccount26Txt: Label 'Non budget tax on account 26';
        TN_Nonbudgettaxonaccount44Txt: Label 'Non budget tax on account 44';
        TN_NonbudgettaxreportingTxt: Label 'Non budget tax reporting';
        TN_OtherincomeTxt: Label 'Other income';
        TN_PenaltydeductionsTxt: Label 'Penalty deductions';
        TN_CompensationforpersonalautousageTxt: Label 'Compensation for personal auto usage';
        TN_PlannedadvanceTxt: Label 'Planned advance';
        TN_ProfessionalunionpaymentTxt: Label 'Professional union payment';
        TN_SalaryTxt: Label 'Salary';
        TN_SalarydifferenceTxt: Label 'Salary difference';
        TN_SicklistpayTxt: Label 'Sick list pay';
        TN_SicklistpayforchildcareTxt: Label 'Sick list pay for childcare';
        TN_SicklistpayforhomesicknessTxt: Label 'Sick list pay for homesickness';
        TN_SicklistpayforinjuryTxt: Label 'Sick list pay for injury';
        TN_SicklistpayforpregnancyTxt: Label 'Sick list pay for pregnancy';
        TN_ChernobylvacationpayTxt: Label 'Chernobyl vacation pay';
        TN_ChildcarevacationpayTxt: Label 'Childcare vacation pay';
        TN_VacationcompensationTxt: Label 'Vacation compensation';
        TN_EducationvacationpayTxt: Label 'Education vacation pay';
        TN_RegularvacationpayTxt: Label 'Regular vacation pay';
        TAG_ABSENCETIMETxt: Label 'ABSENCE TIME';
        TAG_AHCALCTxt: Label 'AH CALC';
        TAG_HOLIDAYTIMETxt: Label 'HOLIDAY TIME';
        TAG_IDLETIMETxt: Label 'IDLE TIME';
        TAG_NIGHTTIMETxt: Label 'NIGHT TIME';
        TAG_OVERTIME15Txt: Label 'OVERTIME 1.5';
        TAG_OVERTIME20Txt: Label 'OVERTIME 2.0';
        TAG_PAIDTxt: Label 'PAID';
        TAG_PLANNEDTIMETxt: Label 'PLANNED TIME';
        TAG_SICKTxt: Label 'SICK';
        TAG_TARIFFTIMETxt: Label 'TARIFF TIME';
        TAG_TASKWORKTIMETxt: Label 'TASK WORK TIME';
        TAG_WEEKENDTIMETxt: Label 'WEEKEND TIME';
        TAG_VACPERCHGBYDOCTxt: Label 'VAC PER CHG BY DOC';
        TAG_VACPERCHGPERIODTxt: Label 'VAC PER CHG PERIOD';
        TAG_ANNUALVACATIONTxt: Label 'ANNUAL VACATION';
        TAG_P4WORKTIMETxt: Label 'P-4 WORK TIME';
        TAG_PREGNSLTxt: Label 'PREGN SL';
        TAC_BTxt: Label 'B';
        TAC_BDTTxt: Label 'BDT';
        TAC_BPTTxt: Label 'BP';
        TAC_BUSTxt: Label 'BUS';
        TAC_VMTxt: Label 'VM';
        TAC_VPTxt: Label 'VP';
        TAC_V1Txt: Label 'V1';
        TAC_V2Txt: Label 'V2';
        TAC_GTxt: Label 'G';
        TAC_DBTxt: Label 'DB';
        TAC_DOTxt: Label 'DO';
        TAC_ZBTxt: Label 'ZB';
        TAC_KTxt: Label 'K';
        TAC_LCHTxt: Label 'LCH';
        TAC_NTxt: Label 'N';
        TAC_NBTxt: Label 'NB';
        TAC_NVTxt: Label 'NV';
        TAC_NZTxt: Label 'NZ';
        TAC_NNTxt: Label 'NN';
        TAC_NOTxt: Label 'NO';
        TAC_NPTxt: Label 'NP';
        TAC_NSTxt: Label 'NS';
        TAC_OVTxt: Label 'OV';
        TAC_ODTxt: Label 'OD';
        TAC_OJTxt: Label 'OJ';
        TAC_OJ1Txt: Label 'OJ1';
        TAC_OJ2Txt: Label 'OJ2';
        TAC_OJ3Txt: Label 'OJ3';
        TAC_OZTxt: Label 'OZ';
        TAC_OZCHTxt: Label 'OZCH';
        TAC_OTTxt: Label 'OT';
        TAC_PVTxt: Label 'PV';
        TAC_PKTxt: Label 'PK';
        TAC_PMTxt: Label 'PM';
        TAC_PRTxt: Label 'PR';
        TAC_RTxt: Label 'RT';
        TAC_RV1Txt: Label 'RV1';
        TAC_RV2Txt: Label 'RV2';
        TAC_RPTxt: Label 'RP';
        TAC_S15Txt: Label 'S15';
        TAC_S20Txt: Label 'S20';
        TAC_TTxt: Label 'T';
        TAC_UTxt: Label 'U';
        TAC_UVTxt: Label 'UV';
        TAC_UDTxt: Label 'UD';
        TAC_YATxt: Label 'YA';
        DRC_CH58P2Txt: Label 'CH58 P2';
        DRC_CH72P1Txt: Label 'CH72 P1';
        DRC_CH72P2Txt: Label 'CH72 P2';
        DRC_CH73Txt: Label 'CH73';
        DRC_CH75Txt: Label 'CH75';
        DRC_CH78Txt: Label 'CH78';
        DRC_CH80P1Txt: Label 'CH80 P1';
        DRC_CH80P2Txt: Label 'CH80 P2';
        DRC_CH81Txt: Label 'CH81';
        DRC_CH83Txt: Label 'CH83';
        DRC_CH84Txt: Label 'CH84';
        GD_FAGCITxt: Label 'FAGCI';
        GD_FBSTxt: Label 'FBS';
        GD_FSSTxt: Label 'FSS';
        GD_NAVYTxt: Label 'NAVY';
        GD_ENGINEERINGTxt: Label 'ENGINEERING';
        GD_AFTxt: Label 'AF';
        GD_ENGTECHTxt: Label 'ENGTECH';
        GD_POLITTxt: Label 'POLIT';
        GD_SAILORTxt: Label 'SAILOR';
        GD_LUBERCITxt: Label 'LUBERCI';
        GD_CARICINOTxt: Label 'CARICINO';
        GD_IZMAILOVOTxt: Label 'IZMAILOVO';
        GD_MOSSADTxt: Label 'MOSSAD';
        GD_MOSNWADTxt: Label 'MOSNWAD';
        GD_XISBTxt: Label 'XISB';
        GD_REGISTRTxt: Label 'REGISTR';
        GD_BIRTHTxt: Label 'BIRTH';
        GD_PERMANTxt: Label 'PERMAN';
        FN_AdvanceamountbyrateandworkingdaysTxt: Label 'Advance amount by rate and working days';
        FN_AdvanceamountbyrateandworkinghoursTxt: Label 'Advance amount by rate and working hours';
        FN_PayrollAmountYTDTxt: Label 'Payroll Amount YTD';
        FN_BalancetoDateforcurrentelementTxt: Label 'Balance to Date for current element';
        FN_CalendarActionDayswithinPeriodTxt: Label 'Calendar Action Days within Period';
        FN_CalendarDaysPeriodTxt: Label 'Calendar Days Period Txt';
        FN_CalendarDaysWagePeriodTxt: Label 'Calendar Days Wage Period';
        FN_AmountbyrateandcalendarhoursTxt: Label 'Amount by rate and calendar hours';
        FN_CalendarWorkingActionDayswithinPeriodTxt: Label 'Calendar Working Action Days within Period';
        FN_CalendarWorkingDaysPeriodTxt: Label 'Calendar Working Days Period';
        FN_CalendarWorkingDaysperYearTxt: Label 'Calendar Working Days per Year';
        FN_CalendarWorkingHoursPeriodTxt: Label 'Calendar Working Hours Period';
        FN_CalendarWorkingHoursperYearTxt: Label 'Calendar Working Hours per Year';
        FN_CalculateBaseAmountforDocumentTxt: Label 'Calculate Base Amount for Document';
        FN_CalculateBaseBalanceforLedgerEntriesTxt: Label 'Calculate Base Balance for Ledger Entries';
        FN_CalculatedeductionasratemultipliedbyquantityTxt: Label 'Calculate deduction as rate multiplied by quantity';
        FN_TotalEarningsYTDTxt: Label 'Total Earnings YTD';
        FN_EmployeeBaseSalaryPeriodTxt: Label 'Employee Base Salary Period';
        FN_EmployeeExtraSalaryPeriodTxt: Label 'Employee Extra Salary Period';
        FN_ExtrapaybyhoursandtimeactivitygroupTxt: Label 'Extra pay by hours and time activity group';
        FN_GetaverageearningsdataTxt: Label 'Get average earnings data';
        FN_GetrangecoefficientTxt: Label 'Get range coefficient';
        FN_GetdeductionamountTxt: Label 'Get deduction amount';
        FN_GetrangemaxamountTxt: Label 'Get range max amount';
        FN_GetrangeminamountTxt: Label 'Get range min amount';
        FN_GetnumberofserviceyearsTxt: Label 'Get number of service years';
        FN_GetstartingbalanceTxt: Label 'Get starting balance';
        FN_GettaxrateTxt: Label 'Get tax rate';
        FN_IncomeincludingearilercalculatedamountsTxt: Label 'Income including eariler calculated amounts';
        FN_TotalIncomeTaxAmountYTDTxt: Label 'Total Income Tax Amount YTD';
        FN_GetmaximaldailyAEpayTxt: Label 'Get maximal daily AE pay';
        FN_GetmaximummonthlyAEpayTxt: Label 'Get maximum monthly AE pay';
        FN_AmountbyrateandworkingdaysTxt: Label 'Amount by rate and working days';
        FN_AmountbyrateandworkinghoursTxt: Label 'Amount by rate and working hours';
        FN_NDFLAmountYTDTxt: Label 'NDFL Amount YTD';
        FN_NDFLTaxableAmountYTDTxt: Label 'NDFL Taxable Amount YTD';
        FN_PaidfromcashdeskTxt: Label 'Paid from cashdesk';
        FN_ReceiveddeductionYTDbeforeemploymentby2NDFLTxt: Label 'Received deduction YTD before employment by 2NDFL';
        FN_IncomeamountYTDbeforeemploymentby2NDFLTxt: Label 'Income amount YTD before employment by 2NDFL';
        FN_IncometaxaccruedYTDbeforeemploymentby2NDFLTxt: Label 'Income tax accrued YTD before employment by 2NDFL';
        FN_IncometaxpaidYTDbeforeemploymentby2NDFLTxt: Label 'Income tax paid YTD before employment by 2NDFL';
        FN_SalaryrateforpreviousperiodTxt: Label 'Salary rate for previous period';
        FN_CalculatePropertyDeductionTxt: Label 'Calculate Property Deduction';
        FN_TimesheetDaysPeriodTimeActivityGroupTxt: Label 'Timesheet Days Period Time Activity Group';
        FN_TimesheetHoursPeriodTimeActivityGroupTxt: Label 'Timesheet Hours Period Time Activity Group';
        FN_LaborContractCivilContractTxt: Label 'Labor Contract Civil Contract';

    [Scope('OnPrem')]
    procedure SetTestMode(NewTestMode: Boolean)
    begin
        TestMode := NewTestMode;
    end;

    [Scope('OnPrem')]
    procedure FunctionCode(FunctionCode: Text[30]): Text[30]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(FunctionCode);

        case FunctionCode of
            'ADVANCE RATE DAYS':
                exit(F_ADVANCERATEDAYSTxt);
            'ADVANCE RATE HOURS':
                exit(F_ADVANCERATEHOURSTxt);
            'AMOUNT YTD':
                exit(F_AMOUNTYTDTxt);
            'BALANCE TO DATE':
                exit(F_BALANCETODATETxt);
            'CAL DAYS ACTION':
                exit(F_CALDAYSACTIONTxt);
            'CAL DAYS PERIOD':
                exit(F_CALDAYSPERIODTxt);
            'CAL DAYS WAGE PERIOD':
                exit(F_CALDAYSWAGEPERIODTxt);
            'CAL DAYS PERIOD BY RATE':
                exit(F_CALDAYSPERIODBYRATETxt);
            'CAL HOURS PERIOD BY RATE':
                exit(F_CALHOURSPERIODBYRATETxt);
            'CAL WORK DAYS ACTION':
                exit(F_CALWORKDAYSACTIONTxt);
            'CAL WORK DAYS PERIOD':
                exit(F_CALWORKDAYSPERIODTxt);
            'CAL WORK DAYS YEAR':
                exit(F_CALWORKDAYSYEARTxt);
            'CAL WORK HOURS PERIOD':
                exit(F_CALWORKHOURSPERIODTxt);
            'CAL WORK HOURS YEAR':
                exit(F_CALWORKHOURSYEARTxt);
            'CALC BASE AMOUNT':
                exit(F_CALCBASEAMOUNTTxt);
            'CALC BASE BALANCE':
                exit(F_CALCBASEBALANCETxt);
            'DEDUCTION AMOUNT BY QTY':
                exit(F_DEDUCTIONAMOUNTBYQTYTxt);
            'EARNINGS YTD':
                exit(F_EARNINGSYTDTxt);
            'EMPLOYEE BASE SALARY':
                exit(F_EMPLOYEEBASESALARYTxt);
            'EMPLOYEE EXTRA SALARY':
                exit(F_EMPLOYEEEXTRASALARYTxt);
            'EXTRAPAY BY HOURS':
                exit(F_EXTRAPAYBYHOURSTxt);
            'GET AE DATA':
                exit(F_GETAEDATATxt);
            'GET COEFFICIENT':
                exit(F_GETCOEFFICIENTTxt);
            'GET DEDUCTION':
                exit(F_GETDEDUCTIONTxt);
            'GET ENTRY AMOUNT':
                exit(F_GETENTRYAMOUNTTxt);
            'GET ENTRY QTY':
                exit(F_GETENTRYQTYTxt);
            'GET MAX AMOUNT':
                exit(F_GETMAXAMOUNTTxt);
            'GET MIN AMOUNT':
                exit(F_GETMINAMOUNTTxt);
            'GET SERVICE YEARS':
                exit(F_GETSERVICEYEARSTxt);
            'GET START BALANCE':
                exit(F_GETSTARTBALANCETxt);
            'GET TAX RATE AMT':
                exit(F_GETTAXRATEAMTTxt);
            'INCOME DISCOUNT':
                exit(F_INCOMEDISCOUNTTxt);
            'INCOME TAX AMOUNT YTD':
                exit(F_INCOMETAXAMOUNTYTDTxt);
            'LABOR CONTRACT TYPE':
                exit(F_LABORCONTRACTTYPETxt);
            'MAX DAILY AE PAY':
                exit(F_MAXDAILYAEPAYTxt);
            'MAX MONTHLY AE PAY':
                exit(F_MAXMONTHLYAEPAYTxt);
            'MONTHLY RATE DAYS':
                exit(F_MONTHLYRATEDAYSTxt);
            'MONTHLY RATE HOURS':
                exit(F_MONTHLYRATEHOURSTxt);
            'NDFL AMOUNT YTD':
                exit(F_NDFLAMOUNTYTDTxt);
            'NDFL TAXABLE YTD':
                exit(F_NDFLTAXABLEYTDTxt);
            'PAID FROM CASHDESK':
                exit(F_PAIDFROMCASHDESKTxt);
            'PREV DEDUCTION AMOUNT':
                exit(F_PREVDEDUCTIONAMOUNTTxt);
            'PREV INCOME AMOUNT':
                exit(F_PREVINCOMEAMOUNTTxt);
            'PREV INCOME TAX ACCRUED':
                exit(F_PREVINCOMETAXACCRUEDTxt);
            'PREV INCOME TAX PAID':
                exit(F_PREVINCOMETAXPAIDTxt);
            'PREV PERIOD RATE':
                exit(F_PREVPERIODRATETxt);
            'PROPERTY DEDUCTION':
                exit(F_PROPERTYDEDUCTIONTxt);
            'TIMESHEET DAYS':
                exit(F_TIMESHEETDAYSTxt);
            'TIMESHEET HOURS':
                exit(F_TIMESHEETHOURSTxt);
            else
                exit(FunctionCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure FunctionName(FunctionName: Text[80]): Text[80]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(FunctionName);

        case FunctionName of
            'Advance amount by rate and working days':
                exit(FN_AdvanceamountbyrateandworkingdaysTxt);
            'Advance amount by rate and working hours':
                exit(FN_AdvanceamountbyrateandworkinghoursTxt);
            'Payroll Amount YTD':
                exit(FN_PayrollAmountYTDTxt);
            'Balance to Date for current element':
                exit(FN_BalancetoDateforcurrentelementTxt);
            'Calendar Action Days within Period':
                exit(FN_CalendarActionDayswithinPeriodTxt);
            'Calendar Days (Period)':
                exit(FN_CalendarDaysPeriodTxt);
            'Calendar Days (Wage Period)':
                exit(FN_CalendarDaysWagePeriodTxt);
            'Amount by rate and calendar hours':
                exit(FN_AmountbyrateandcalendarhoursTxt);
            'Calendar Working Action Days within Period':
                exit(FN_CalendarWorkingActionDayswithinPeriodTxt);
            'Calendar Working Days (Period)':
                exit(FN_CalendarWorkingDaysPeriodTxt);
            'Calendar Working Days per Year':
                exit(FN_CalendarWorkingDaysperYearTxt);
            'Calendar Working Hours (Period)':
                exit(FN_CalendarWorkingHoursPeriodTxt);
            'Calendar Working Hours per Year':
                exit(FN_CalendarWorkingHoursperYearTxt);
            'Calculate Base Amount for Document':
                exit(FN_CalculateBaseAmountforDocumentTxt);
            'Calculate Base Balance for Ledger Entries':
                exit(FN_CalculateBaseBalanceforLedgerEntriesTxt);
            'Calculate deduction as rate multiplied by quantity':
                exit(FN_CalculatedeductionasratemultipliedbyquantityTxt);
            'Total Earnings YTD':
                exit(FN_TotalEarningsYTDTxt);
            'Employee Base Salary (Period)':
                exit(FN_EmployeeBaseSalaryPeriodTxt);
            'Employee Extra Salary (Period)':
                exit(FN_EmployeeExtraSalaryPeriodTxt);
            'Extrapay by hours and time activity group':
                exit(FN_ExtrapaybyhoursandtimeactivitygroupTxt);
            'Get average earnings data':
                exit(FN_GetaverageearningsdataTxt);
            'Get range coefficient':
                exit(FN_GetrangecoefficientTxt);
            'Get deduction amount':
                exit(FN_GetdeductionamountTxt);
            'Get range max amount':
                exit(FN_GetrangemaxamountTxt);
            'Get range min amount':
                exit(FN_GetrangeminamountTxt);
            'Get number of service years':
                exit(FN_GetnumberofserviceyearsTxt);
            'Get starting balance':
                exit(FN_GetstartingbalanceTxt);
            'Get tax rate':
                exit(FN_GettaxrateTxt);
            'Income including eariler calculated amounts':
                exit(FN_IncomeincludingearilercalculatedamountsTxt);
            'Total Income Tax Amount YTD':
                exit(FN_TotalIncomeTaxAmountYTDTxt);
            'Get maximal daily AE pay':
                exit(FN_GetmaximaldailyAEpayTxt);
            'Get maximum monthly AE pay':
                exit(FN_GetmaximummonthlyAEpayTxt);
            'Amount by rate and working days':
                exit(FN_AmountbyrateandworkingdaysTxt);
            'Amount by rate and working hours':
                exit(FN_AmountbyrateandworkinghoursTxt);
            'NDFL Amount YTD':
                exit(FN_NDFLAmountYTDTxt);
            'NDFL Taxable Amount YTD':
                exit(FN_NDFLTaxableAmountYTDTxt);
            'Paid from cash desk':
                exit(FN_PaidfromcashdeskTxt);
            'Received deduction YTD before employment (by 2-NDFL)':
                exit(FN_ReceiveddeductionYTDbeforeemploymentby2NDFLTxt);
            'Income amount YTD before employment (by 2-NDFL)':
                exit(FN_IncomeamountYTDbeforeemploymentby2NDFLTxt);
            'Income tax accrued YTD before employment (by 2-NDFL)':
                exit(FN_IncometaxaccruedYTDbeforeemploymentby2NDFLTxt);
            'Income tax paid YTD before employment (by 2-NDFL)':
                exit(FN_IncometaxpaidYTDbeforeemploymentby2NDFLTxt);
            'Salary rate for previous period':
                exit(FN_SalaryrateforpreviousperiodTxt);
            'Calculate Property Deduction':
                exit(FN_CalculatePropertyDeductionTxt);
            'Timesheet Days (Period, Time Activity Group)':
                exit(FN_TimesheetDaysPeriodTimeActivityGroupTxt);
            'Timesheet Hours (Period, Time Activity Group)':
                exit(FN_TimesheetHoursPeriodTimeActivityGroupTxt);
            'Labor Contract = 0, Civil Contract = 1':
                exit(FN_LaborContractCivilContractTxt);
            else
                exit(FunctionName);
        end;

        exit(FunctionName);
    end;

    [Scope('OnPrem')]
    procedure ElementCode(ElementCode: Text[20]): Text[20]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(ElementCode);

        if CopyStr(ElementCode, 1, 1) in ['A' .. 'M'] then
            exit(ElementCodeFromAToM(ElementCode));

        exit(ElementCodeFromN(ElementCode));
    end;

    local procedure ElementCodeFromAToM(ElementCode: Text[20]): Text[20]
    begin
        case ElementCode of
            'ADVANCE WORKED DAYS':
                exit(EC_ADVANCEWORKEDDAYSTxt);
            'ADVANCE WORKED HOURS':
                exit(EC_ADVANCEWORKEDHOURSTxt);
            'AMOUNT DUE PAY':
                exit(EC_AMOUNTDUEPAYTxt);
            'AUTHOR PAY':
                exit(EC_AUTHORPAYTxt);
            'BENEFIT CHILD BIRTH':
                exit(EC_BENEFITCHILDBIRTHTxt);
            'BENEFIT EARLY PREG':
                exit(EC_BENEFITEARLYPREGTxt);
            'BENEFIT FUNERAL':
                exit(EC_BENEFITFUNERALTxt);
            'BENEFIT ORDER':
                exit(EC_BENEFITORDERTxt);
            'BONUS AMOUNT':
                exit(EC_BONUSAMOUNTTxt);
            'BONUS ANNUAL AMT':
                exit(EC_BONUSANNUALAMTTxt);
            'BONUS ANNUAL %':
                exit(EC_BONUSANNUALPERCTxt);
            'BONUS MONTHLY AMT':
                exit(EC_BONUSMONTHLYAMTTxt);
            'BONUS MONTHLY %':
                exit(EC_BONUSMONTHLYPERCTxt);
            'BONUS MONTHLY % LM':
                exit(EC_BONUSMONTHLYPERCLMTxt);
            'BONUS QUARTERLY AMT':
                exit(EC_BONUSQUARTERLYAMTTxt);
            'BONUS QUARTERLY %':
                exit(EC_BONUSQUARTERLYPERCTxt);
            'BUSINESS TRAVEL':
                exit(EC_BUSINESSTRAVELTxt);
            'CONTRACT SERV':
                exit(EC_CONTRACTSERVTxt);
            'CONTRACT WORK':
                exit(EC_CONTRACTWORKTxt);
            'DEDUCT MEALS':
                exit(EC_DEDUCTMEALSTxt);
            'DEDUCT PROPERTY 313':
                exit(EC_DEDUCTPROPERTY313Txt);
            'DEDUCT103':
                exit(EC_DEDUCTTxt + '103');
            'DEDUCT104':
                exit(EC_DEDUCTTxt + '104');
            'DEDUCT105':
                exit(EC_DEDUCTTxt + '105');
            'DEDUCT108':
                exit(EC_DEDUCTTxt + '108');
            'DEDUCT109':
                exit(EC_DEDUCTTxt + '109');
            'DEDUCT110':
                exit(EC_DEDUCTTxt + '110');
            'DEDUCT111':
                exit(EC_DEDUCTTxt + '111');
            'DEDUCT112':
                exit(EC_DEDUCTTxt + '112');
            'DEDUCT113':
                exit(EC_DEDUCTTxt + '113');
            'DEDUCT501':
                exit(EC_DEDUCTTxt + '501');
            'DEDUCT503':
                exit(EC_DEDUCTTxt + '503');
            'DISMISSAL COMP. 3 M':
                exit(EC_DISMISSALCOMP3MTxt);
            'DISMISSAL PAY AMOUNT':
                exit(EC_DISMISSALPAYAMOUNTTxt);
            'DISMISSAL PAY DAYS':
                exit(EC_DISMISSALPAYDAYSTxt);
            'DIVIDENDS':
                exit(EC_DIVIDENDSTxt);
            'EXEC ACT AMT':
                exit(EC_EXECACTAMTTxt);
            'EXEC ACT TRANSF AMT':
                exit(EC_EXECACTTRANSFAMTTxt);
            'EXEC ACT TRANSF %':
                exit(EC_EXECACTTRANSFPERTxt);
            'EXEC ACT %':
                exit(EC_EXECACTPERTxt);
            'EXTRAPAY AMT':
                exit(EC_EXTRAPAYAMTTxt);
            'EXTRAPAY DAY':
                exit(EC_EXTRAPAYDAYTxt);
            'EXTRAPAY DAY %':
                exit(EC_EXTRAPAYDAYPERTxt);
            'EXTRAPAY HOLIDAY AMT':
                exit(EC_EXTRAPAYHOLIDAYAMTTxt);
            'EXTRAPAY HOLIDAYS':
                exit(EC_EXTRAPAYHOLIDAYSTxt);
            'EXTRAPAY HOURS':
                exit(EC_EXTRAPAYHOURSTxt);
            'EXTRAPAY HOURS %':
                exit(EC_EXTRAPAYHOURSPERTxt);
            'EXTRAPAY NIGHT':
                exit(EC_EXTRAPAYNIGHTTxt);
            'EXTRAPAY NIGHT AMT':
                exit(EC_EXTRAPAYNIGHTAMTTxt);
            'EXTRAPAY NO WORK AMT':
                exit(EC_EXTRAPAYNOWORKAMTTxt);
            'EXTRAPAY NO WORK DS':
                exit(EC_EXTRAPAYNOWORKDSTxt);
            'EXTRAPAY NO WORK HS':
                exit(EC_EXTRAPAYNOWORKHSTxt);
            'EXTRAPAY OVERT AMT':
                exit(EC_EXTRAPAYOVERTAMTTxt);
            'EXTRAPAY OVERT 1.5':
                exit(EC_EXTRAPAYOVERT15Txt);
            'EXTRAPAY OVERT 2':
                exit(EC_EXTRAPAYOVERT2Txt);
            'GIFTS':
                exit(EC_GIFTSTxt);
            'INCOME TAX DIVID':
                exit(EC_INCOMETAXDIVIDTxt);
            'INCOME TAX 13%':
                exit(EC_INCOMETAX13PERTxt);
            'INCOME TAX 30%':
                exit(EC_INCOMETAX30PERTxt);
            'INCOME TAX 35%':
                exit(EC_INCOMETAX35PERTxt);
            'INTER PERIOD PAY':
                exit(EC_INTERPERIODPAYTxt);
            'LOAN':
                exit(EC_LOANTxt);
            'LOAN BENEFIT':
                exit(EC_LOANBENEFITTxt);
            'LOAN PAY':
                exit(EC_LOANPAYTxt);
            else
                exit(ElementCode);
        end;
    end;

    local procedure ElementCodeFromN(ElementCode: Text[20]): Text[20]
    begin
        case ElementCode of
            'OTHER INCOME TAXABLE':
                exit(EC_OTHERINCOMETAXABLETxt);
            'P-4 TOTAL WAGES':
                exit(EC_P4TOTALWAGESTxt);
            'P-4 TOTAL BENEFITS':
                exit(EC_P4TOTALBENEFITSTxt);
            'PAY AE TIMESHEET':
                exit(EC_PAYAETIMESHEETTxt);
            'PAY AVG EARNINGS':
                exit(EC_PAYAVGEARNINGSTxt);
            'PAY CONTR VM':
                exit(EC_PAYCONTRVMTxt);
            'PAY GOVERN DUTIES':
                exit(EC_PAYGOVERNDUTIESTxt);
            'PAY MEALS':
                exit(EC_PAYMEALSTxt);
            'PAY MEALS NAT':
                exit(EC_PAYMEALSNATTxt);
            'PAY SL AMT':
                exit(EC_PAYSLAMTTxt);
            'PAY SL AMT OWN':
                exit(EC_PAYSLAMTOWNTxt);
            'PAY SL CHILD AMT':
                exit(EC_PAYSLCHILDAMTTxt);
            'PAY SL CHILD DAYS':
                exit(EC_PAYSLCHILDDAYSTxt);
            'PAY SL DAYS':
                exit(EC_PAYSLDAYSTxt);
            'PAY SL HOME AMT':
                exit(EC_PAYSLHOMEAMTTxt);
            'PAY SL HOME DAYS':
                exit(EC_PAYSLHOMEDAYSTxt);
            'PAY SL INJURY AMT':
                exit(EC_PAYSLINJURYAMTTxt);
            'PAY SL INJURY DAYS':
                exit(EC_PAYSLINJURYDAYSTxt);
            'PAY SL PREG AMT':
                exit(EC_PAYSLPREGAMTTxt);
            'PAY SL PREG DAYS':
                exit(EC_PAYSLPREGDAYSTxt);
            'PENALTY':
                exit(EC_PENALTYTxt);
            'PERSONAL AUTO':
                exit(EC_PERSONALAUTOTxt);
            'PLANNED ADVANCE':
                exit(EC_PLANNEDADVANCETxt);
            'PROF UNION PAY':
                exit(EC_PROFUNIONPAYTxt);
            'SALARY AMOUNT':
                exit(EC_SALARYAMOUNTTxt);
            'SALARY BASE':
                exit(EC_SALARYBASETxt);
            'SALARY DAY':
                exit(EC_SALARYDAYTxt);
            'SALARY DIFF AMT':
                exit(EC_SALARYDIFFAMTTxt);
            'SALARY DIFF DAY':
                exit(EC_SALARYDIFFDAYTxt);
            'SALARY DIFF HOUR':
                exit(EC_SALARYDIFFHOURTxt);
            'SALARY HOUR':
                exit(EC_SALARYHOURTxt);
            'SALARY TARIFF':
                exit(EC_SALARYTARIFFTxt);
            'START BALANCE':
                exit(EC_STARTBALANCETxt);
            'TAX FED FMI':
                exit(EC_TAXFEDFMITxt);
            'TAX FED FMI DIS':
                exit(EC_TAXFEDFMIDISTxt);
            'TAX FSI':
                exit(EC_TAXFSITxt);
            'TAX FSI DIS':
                exit(EC_TAXFSIDISTxt);
            'TAX FSI INJ':
                exit(EC_TAXFSIINJTxt);
            'TAX FSI INJ DIS':
                exit(EC_TAXFSIINJDISTxt);
            'TAX PF INS':
                exit(EC_TAXPFINSTxt);
            'TAX PF INS DIS':
                exit(EC_TAXPFINSDISTxt);
            'TAX PF SAV':
                exit(EC_TAXPFSAVTxt);
            'TAX REP PF INS LIMIT':
                exit(EC_TAXREPPFINSLIMITTxt);
            'TAX REP PF MI BASE':
                exit(EC_TAXREPPFMIBASETxt);
            'TAX REP PF MI NO TAX':
                exit(EC_TAXREPPFMINOTAXTxt);
            'TAX REP PF MI OVER':
                exit(EC_TAXREPPFMIOVERTxt);
            'TAX REP FSI BASE':
                exit(EC_TAXREPFSIBASETxt);
            'TAX REP FSI NO TAX':
                exit(EC_TAXREPFSINOTAXTxt);
            'TAX REP FSI OVER':
                exit(EC_TAXREPFSIOVERTxt);
            'TAX REP SPECIAL1':
                exit(EC_TAXREPSPECIAL1Txt);
            'TAX REP SPECIAL2':
                exit(EC_TAXREPSPECIAL2Txt);
            'TAX TER FMI':
                exit(EC_TAXTERFMITxt);
            'TOTAL BONUS':
                exit(EC_TOTALBONUSTxt);
            'TOTAL DEDUCTION':
                exit(EC_TOTALDEDUCTIONTxt);
            'TOTAL FED FMI':
                exit(EC_TOTALFEDFMITxt);
            'TOTAL FSI':
                exit(EC_TOTALFSITxt);
            'TOTAL FSI INJURY':
                exit(EC_TOTALFSIINJURYTxt);
            'TOTAL INCOME TAX':
                exit(EC_TOTALINCOMETAXTxt);
            'TOTAL PF ACCUM':
                exit(EC_TOTALPFACCUMTxt);
            'TOTAL PF INSUR':
                exit(EC_TOTALPFINSURTxt);
            'TOTAL TAX DEDUCTION':
                exit(EC_TOTALTAXDEDUCTIONTxt);
            'TOTAL TER FMI':
                exit(EC_TOTALTERFMITxt);
            'TOTAL WAGE':
                exit(EC_TOTALWAGETxt);
            'VAC CHERNOBYL':
                exit(EC_VACCHERNOBYLTxt);
            'VAC CHILD 3 DAYS':
                exit(EC_VACCHILD3DAYSTxt);
            'VAC CHILD1 1.5 DAYS':
                exit(EC_VACCHILD115DAYSTxt);
            'VAC CHILD2 1.5 DAYS':
                exit(EC_VACCHILD215DAYSTxt);
            'VAC CHILD3 1.5 DAYS':
                exit(EC_VACCHILD315DAYSTxt);
            'VAC COMPENS':
                exit(EC_VACCOMPENSTxt);
            'VAC COMPENS AMT':
                exit(EC_VACCOMPENSAMTTxt);
            'VAC EDUCATION':
                exit(EC_VACEDUCATIONTxt);
            'VAC EDUCATION AMT':
                exit(EC_VACEDUCATIONAMTTxt);
            'VAC REGULAR':
                exit(EC_VACREGULARTxt);
            'VAC REGULAR AMT':
                exit(EC_VACREGULARAMTTxt);
            'VAC W/O PAYMENT':
                exit(EC_VACWOPAYMENTTxt);
            else
                exit(ElementCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure ElementGroup(GroupCode: Code[20]): Code[20]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(GroupCode);

        case GroupCode of
            'ADVANCE PAY':
                exit(EG_ADVANCEPAYTxt);
            'BASE SALARY':
                exit(EG_BASESALARYTxt);
            'BONUS':
                exit(EG_BONUSTxt);
            'DEDUCTION':
                exit(EG_DEDUCTIONTxt);
            'DIVIDENDS':
                exit(EG_DIVIDENDSTxt);
            'EXTRA PAY HOLIDAY':
                exit(EG_EXTRAPAYHOLIDAYTxt);
            'EXTRA PAY NIGHT':
                exit(EG_EXTRAPAYNIGHTTxt);
            'EXTRA PAY NO WORK':
                exit(EG_EXTRAPAYNOWORKTxt);
            'EXTRA PAY OTHER':
                exit(EG_EXTRAPAYOTHERTxt);
            'EXTRA PAY OVERT':
                exit(EG_EXTRAPAYOVERTTxt);
            'FUNDS':
                exit(EG_FUNDSTxt);
            'INCOME TAX':
                exit(EG_INCOMETAXTxt);
            'LOAN BENEFIT':
                exit(EG_LOANBENEFITTxt);
            'OTHER':
                exit(EG_OTHERTxt);
            'REPORTING':
                exit(EG_REPORTINGTxt);
            'TAX DEDUCTION':
                exit(EG_TAXDEDUCTIONTxt);
            'SALARY PAY':
                exit(EG_SALARYPAYTxt);
            'SICK LEAVE PAY':
                exit(EG_SICKLEAVEPAYTxt);
            'START BALANCE':
                exit(EG_STARTBALANCETxt);
            'VACATION':
                exit(EG_VACATIONTxt);
            else
                exit(GroupCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure ElementGroupName(GroupName: Text[50]): Text[50]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(GroupName);

        case GroupName of
            'Advance pay':
                exit(EGN_AdvancePayTxt);
            'Base salary':
                exit(EGN_BaseSalaryTxt);
            'Bonuses':
                exit(EGN_BonusesTxt);
            'Deductions':
                exit(EGN_DeductionsTxt);
            'Dividends':
                exit(EGN_DividendsTxt);
            'Extra pay for holiday work':
                exit(EGN_ExtrapayforholidayworkTxt);
            'Extra pay for night work':
                exit(EGN_ExtrapayfornightworkTxt);
            'Extra pay for no work':
                exit(EGN_ExtrapayfornoworkTxt);
            'Extra pay for overtime':
                exit(EGN_ExtrapayforovertimeTxt);
            'Other extra pays':
                exit(EGN_OtherextrapaysTxt);
            'Funds':
                exit(EGN_FundsTxt);
            'Income tax':
                exit(EGN_IncomeTaxTxt);
            'Loan benefit':
                exit(EGN_LoanBenefitTxt);
            'Other':
                exit(EGN_OtherTxt);
            'Reporting elements':
                exit(EGN_ReportingelementsTxt);
            'Salary payments':
                exit(EGN_SalarypaymentsTxt);
            'Sick leave pay':
                exit(EGN_SickleavepayTxt);
            'Starting balance':
                exit(EGN_StartingbalanceTxt);
            'Tax deductions':
                exit(EGN_TaxdeductionsTxt);
            'Vacations':
                exit(EGN_VacationsTxt);
            else
                exit(GroupName);
        end;
    end;

    [Scope('OnPrem')]
    procedure ElementDescription(Description: Text[250]): Text[250]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(Description);

        exit(Description);
    end;

    [Scope('OnPrem')]
    procedure PostingGroupCode(GroupCode: Code[20]): Code[20]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(GroupCode);

        case GroupCode of
            'ADVANTAGE':
                exit(PGC_ADVANTAGETxt);
            'BENEFIT':
                exit(PGC_BENEFITTxt);
            'ALIMONY':
                exit(PGC_ALIMONYTxt);
            'BENEFIT 69 ALL':
                exit(PGC_BENEFIT69ALLTxt);
            'BENEFIT 69 INJ':
                exit(PGC_BENEFIT69INJTxt);
            'BENEFIT 69 NOA':
                exit(PGC_BENEFIT69NOATxt);
            'CONTRACT':
                exit(PGC_CONTRACTTxt);
            'DAMAGE':
                exit(PGC_DAMAGETxt);
            'DEPONENT':
                exit(PGC_DEPONENTTxt);
            'DUE PAY':
                exit(PGC_DUEPAYTxt);
            'EMPL RETURN':
                exit(PGC_EMPLRETURNTxt);
            'EMPL SETTLE':
                exit(PGC_EMPLSETTLETxt);
            'END BALANCE':
                exit(PGC_ENDBALANCETxt);
            'FED FMI-20':
                exit(PGC_FEDFMI20Txt);
            'FED FMI-26':
                exit(PGC_FEDFMI26Txt);
            'FED FMI-44':
                exit(PGC_FEDFMI44Txt);
            'FP VACATION-20':
                exit(PGC_FPVACATION20Txt);
            'FP VACATION-26':
                exit(PGC_FPVACATION26Txt);
            'FP VACATION-44':
                exit(PGC_FPVACATION44Txt);
            'FSI INJ-20':
                exit(PGC_FSIINJ20Txt);
            'FSI INJ-26':
                exit(PGC_FSIINJ26Txt);
            'FSI INJ-44':
                exit(PGC_FSIINJ44Txt);
            'FSI-20':
                exit(PGC_FSI20Txt);
            'FSI-26':
                exit(PGC_FSI26Txt);
            'FSI-44':
                exit(PGC_FSI44Txt);
            'INCOME TAX':
                exit(PGC_INCOMETAXTxt);
            'INTERM PAY':
                exit(PGC_INTERMPAYTxt);
            'LOAN PAY':
                exit(PGC_LOANPAYTxt);
            'MEALS':
                exit(PGC_MEALSTxt);
            'PAYR-20':
                exit(PGC_PAYR20Txt);
            'PAYR-26':
                exit(PGC_PAYR26Txt);
            'PAYR-44':
                exit(PGC_PAYR44Txt);
            'PENALTY':
                exit(PGC_PENALTYTxt);
            'PF INS-20':
                exit(PGC_PFINS20Txt);
            'PF INS-26':
                exit(PGC_PFINS26Txt);
            'PF INS-44':
                exit(PGC_PFINS44Txt);
            'PF SAV-20':
                exit(PGC_PFSAV20Txt);
            'PF SAV-26':
                exit(PGC_PFSAV26Txt);
            'PF SAV-44':
                exit(PGC_PFSAV44Txt);
            'PF 14%-20':
                exit(PGC_PF14PER20Txt);
            'PF 14%-26':
                exit(PGC_PF14PER26Txt);
            'PF 14%-44':
                exit(PGC_PF14PER44Txt);
            'PROF UNION PAY':
                exit(PGC_PROFUNIONPAYTxt);
            'PROFIT PAY':
                exit(PGC_PROFITPAYTxt);
            'START BALANCE':
                exit(PGC_STARTBALANCETxt);
            'TER FMI-20':
                exit(PGC_TERFMI20Txt);
            'TER FMI-26':
                exit(PGC_TERFMI26Txt);
            'TER FMI-44':
                exit(PGC_TERFMI44Txt);
            else
                exit(GroupCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcGroupCode(GroupCode: Code[10]): Code[10]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(GroupCode);

        case GroupCode of
            'ADVANCE':
                exit(GC_ADVANCETxt);
            'DISABLED20':
                exit(GC_DISABLED20Txt);
            'INTERBONUS':
                exit(GC_INTERBONUSTxt);
            'INTERPAYM':
                exit(GC_INTERPAYMTxt);
            'ABSINTPAY':
                exit(GC_ABSINTPAYTxt);
            'PAYR-20':
                exit(GC_PAYR20Txt);
            'PAYR-26':
                exit(GC_PAYR26Txt);
            'PAYR-44':
                exit(GC_PAYR44Txt);
            else
                exit(GroupCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcGroupName(GroupName: Text[50]): Text[50]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(GroupName);

        case GroupName of
            'Payroll Advance':
                exit(GN_PayrollAdvanceTxt);
            'Disabled on account 20':
                exit(GN_Disabledonaccount20Txt);
            'Interim Bonus':
                exit(GN_InterimBonusTxt);
            'Interim Payment':
                exit(GN_InterimPaymentTxt);
            'Salary and Taxes on 20 account':
                exit(GN_SalaryandTaxeson20accountTxt);
            'Salary and Taxes on 26 account':
                exit(GN_SalaryandTaxeson26accountTxt);
            'Salary and Taxes on 44 account':
                exit(GN_SalaryandTaxeson44accountTxt);
            else
                exit(GroupName);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcTypeCode(TypeCode: Code[20]): Code[20]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(TypeCode);

        case TypeCode of
            'ADVANTAGE':
                exit(TC_ADVANTAGETxt);
            'ALIMONY':
                exit(TC_ALIMONYTxt);
            'AMOUNT DUE PAY':
                exit(TC_AMOUNTDUEPAYTxt);
            'AUTHOR INCOME':
                exit(TC_AUTHORINCOMETxt);
            'AVG EARNING PAY':
                exit(TC_AVGEARNINGPAYTxt);
            'BENEFIT ORDER':
                exit(TC_BENEFITORDERTxt);
            'BENEFITS':
                exit(TC_BENEFITSTxt);
            'BONUS':
                exit(TC_BONUSTxt);
            'BUSINESS TRAVEL':
                exit(TC_BUSINESSTRAVELTxt);
            'CHERNOBYL PAY':
                exit(TC_CHERNOBYLPAYTxt);
            'DEDUCT CHILDS':
                exit(TC_DEDUCTCHILDRENTxt);
            'DEDUCT MEALS':
                exit(TC_DEDUCTMEALSTxt);
            'DEDUCT OTHERS':
                exit(TC_DEDUCTOTHERSTxt);
            'DEDUCT PROPERTY':
                exit(TC_DEDUCTPROPERTYTxt);
            'DEDUCT STANDARD':
                exit(TC_DEDUCTSTANDARDTxt);
            'DEDUCT 501-503':
                exit(TC_DEDUCT501503Txt);
            'DEPONENT':
                exit(TC_DEPONENTTxt);
            'DISMISSAL PAY':
                exit(TC_DISMISSALPAYTxt);
            'DIVIDENDS':
                exit(TC_DIVIDENDSTxt);
            'EXECUTIVE ACT':
                exit(TC_EXECUTIVEACTTxt);
            'EXECUTIVE ACT ALIM':
                exit(TC_EXECUTIVEACTALIMTxt);
            'EXTRA PAY AMOUNT':
                exit(TC_EXTRAPAYAMOUNTTxt);
            'EXTRA PAY NO WORK':
                exit(TC_EXTRAPAYNOWORKTxt);
            'EXTRA PAY OTHER':
                exit(TC_EXTRAPAYOTHERTxt);
            'EXTRA PAY OVERTIME':
                exit(TC_EXTRAPAYOVERTIMETxt);
            'GIFTS':
                exit(TC_GIFTSTxt);
            'INCOME TAX DIVID':
                exit(TC_INCOMETAXDIVIDTxt);
            'INCOME TAX 13%':
                exit(TC_INCOMETAX13PERTxt);
            'INCOME TAX 35%':
                exit(TC_INCOMETAX35PERTxt);
            'INJURY TAX DISABL-20':
                exit(TC_INJURYTAXDISABL20Txt);
            'INJURY TAX-20':
                exit(TC_INJURYTAX20Txt);
            'INJURY TAX-26':
                exit(TC_INJURYTAX26Txt);
            'INJURY TAX-44':
                exit(TC_INJURYTAX44Txt);
            'INT PERIOD PAY':
                exit(TC_INTPERIODPAYTxt);
            'LOAN PAY':
                exit(TC_LOANPAYTxt);
            'LOAN':
                exit(TC_LOANTxt);
            'NON BUDGET TAX-20':
                exit(TC_NONBUDGETTAX20Txt);
            'NON BUDGET TAX-26':
                exit(TC_NONBUDGETTAX26Txt);
            'NON BUDGET TAX-44':
                exit(TC_NONBUDGETTAX44Txt);
            'NON BUDGET REPORT':
                exit(TC_NONBUDGETREPORTTxt);
            'OTHER INCOME':
                exit(TC_OTHERINCOMETxt);
            'PENALTY':
                exit(TC_PENALTYTxt);
            'PERSONAL AUTO':
                exit(TC_PERSONALAUTOTxt);
            'PLANNED ADVANCE':
                exit(TC_PLANNEDADVANCETxt);
            'PROF UNION PAY':
                exit(TC_PROFUNIONPAYTxt);
            'RETURN AMOUNTS':
                exit(TC_RETURNAMOUNTSTxt);
            'SALARY':
                exit(TC_SALARYTxt);
            'SALARY DIFFERENCE':
                exit(TC_SALARYDIFFERENCETxt);
            'SHORTAGE':
                exit(TC_SHORTAGETxt);
            'SICK LIST PAY':
                exit(TC_SICKLISTPAYTxt);
            'SICK LIST PAY CHILD':
                exit(TC_SICKLISTPAYCHILDTxt);
            'SICK LIST PAY HOME':
                exit(TC_SICKLISTPAYHOMETxt);
            'SICK LIST PAY INJURY':
                exit(TC_SICKLISTPAYINJURYTxt);
            'SICK LIST PAY PREG':
                exit(TC_SICKLISTPAYPREGTxt);
            'VACATION CHERNOBYL':
                exit(TC_VACATIONCHERNOBYLTxt);
            'VACATION CHILD CARE':
                exit(TC_VACATIONCHILDCARETxt);
            'VACATION COMPENSAT':
                exit(TC_VACATIONCOMPENSATTxt);
            'VACATION EDUCATION':
                exit(TC_VACATIONEDUCATIONTxt);
            'VACATION REGULAR':
                exit(TC_VACATIONREGULARTxt);
            else
                exit(TypeCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure CalcTypeName(TypeName: Text[50]): Text[50]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(TypeName);

        case TypeName of
            'Advantages':
                exit(TN_AdvantagesTxt);
            'Amount due pay':
                exit(TN_AmountduepayTxt);
            'Author income':
                exit(TN_AuthorincomeTxt);
            'Pay by average earnings':
                exit(TN_PaybyaverageearningsTxt);
            'Benefit orders':
                exit(TN_BenefitordersTxt);
            'Benefits':
                exit(TN_BenefitsTxt);
            'Bonus':
                exit(TN_BonusTxt);
            'Business travel':
                exit(TN_BusinesstravelTxt);
            'Child tax deductions':
                exit(TN_ChildtaxdeductionsTxt);
            'Meal deductions':
                exit(TN_MealdeductionsTxt);
            'Property tax deductions':
                exit(TN_PropertytaxdeductionsTxt);
            'Standard tax deductions':
                exit(TN_StandardtaxdeductionsTxt);
            '501-503 tax deductions':
                exit(TN_501503taxdeductionsTxt);
            'Dismissal pay':
                exit(TN_DismissalpayTxt);
            'Dividends':
                exit(TN_DividendsTxt);
            'Executive act deductions':
                exit(TN_ExecutiveactdeductionsTxt);
            'Extra pay amounts':
                exit(TN_ExtrapayamountsTxt);
            'No work extra pays':
                exit(TN_NoworkextrapaysTxt);
            'Other extra pays':
                exit(TN_OtherextrapaysTxt);
            'Overttime extra pays':
                exit(TN_OverttimeextrapaysTxt);
            'Gifts':
                exit(TN_GiftsTxt);
            'Income tax for dividends':
                exit(TN_IncometaxfordividendsTxt);
            'Income tax 13%':
                exit(TN_Incometax13PERTxt);
            'Income tax 35%':
                exit(TN_Incometax35PERTxt);
            'Injury tax for disabled on account 20':
                exit(TN_Injurytaxfordisabledonaccount20Txt);
            'Injury tax on account 20':
                exit(TN_Injurytaxonaccount20Txt);
            'Injury tax on account 26':
                exit(TN_Injurytaxonaccount26Txt);
            'Injury tax on account 44':
                exit(TN_Injurytaxonaccount44Txt);
            'Loan':
                exit(TN_LoanTxt);
            'Loan pay':
                exit(TN_LoanpayTxt);
            'Non-budget tax on account 20':
                exit(TN_Nonbudgettaxonaccount20Txt);
            'Non-budget tax on account 26':
                exit(TN_Nonbudgettaxonaccount26Txt);
            'Non-budget tax on account 44':
                exit(TN_Nonbudgettaxonaccount44Txt);
            'Non-budget tax reporting':
                exit(TN_NonbudgettaxreportingTxt);
            'Other income':
                exit(TN_OtherincomeTxt);
            'Penalty deductions':
                exit(TN_PenaltydeductionsTxt);
            'Compensation for personal auto usage':
                exit(TN_CompensationforpersonalautousageTxt);
            'Planned advance':
                exit(TN_PlannedadvanceTxt);
            'Professional union payment':
                exit(TN_ProfessionalunionpaymentTxt);
            'Salary':
                exit(TN_SalaryTxt);
            'Salary difference':
                exit(TN_SalarydifferenceTxt);
            'Sick list pay':
                exit(TN_SicklistpayTxt);
            'Sick list pay for child care':
                exit(TN_SicklistpayforchildcareTxt);
            'Sick list pay for home sickness':
                exit(TN_SicklistpayforhomesicknessTxt);
            'Sick list pay for injury':
                exit(TN_SicklistpayforinjuryTxt);
            'Sick list pay for pregnancy':
                exit(TN_SicklistpayforpregnancyTxt);
            'Chernobyl vacation pay':
                exit(TN_ChernobylvacationpayTxt);
            'Child care vacation pay':
                exit(TN_ChildcarevacationpayTxt);
            'Vacation compensation':
                exit(TN_VacationcompensationTxt);
            'Education vacation pay':
                exit(TN_EducationvacationpayTxt);
            'Regular vacation pay':
                exit(TN_RegularvacationpayTxt);
            else
                exit(TypeName);
        end;
    end;

    [Scope('OnPrem')]
    procedure TimeActivityGroup(GroupCode: Code[20]): Code[20]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(GroupCode);

        case GroupCode of
            'ABSENCE TIME':
                exit(TAG_ABSENCETIMETxt);
            'AH CALC':
                exit(TAG_AHCALCTxt);
            'HOLIDAY TIME':
                exit(TAG_HOLIDAYTIMETxt);
            'IDLE TIME':
                exit(TAG_IDLETIMETxt);
            'NIGHT TIME':
                exit(TAG_NIGHTTIMETxt);
            'OVERTIME15':
                exit(TAG_OVERTIME15Txt);
            'OVERTIME20':
                exit(TAG_OVERTIME20Txt);
            'PAID':
                exit(TAG_PAIDTxt);
            'PLANNED TIME':
                exit(TAG_PLANNEDTIMETxt);
            'SICK':
                exit(TAG_SICKTxt);
            'TARIFF TIME':
                exit(TAG_TARIFFTIMETxt);
            'TASK WORK TIME':
                exit(TAG_TASKWORKTIMETxt);
            'WEEKEND TIME':
                exit(TAG_WEEKENDTIMETxt);
            'VAC PER CHG BY DOC':
                exit(TAG_VACPERCHGBYDOCTxt);
            'VAC PER CHG PERIOD':
                exit(TAG_VACPERCHGPERIODTxt);
            'ANNUAL VACATION':
                exit(TAG_ANNUALVACATIONTxt);
            'P-4 WORK TIME':
                exit(TAG_P4WORKTIMETxt);
            'PREGN SL':
                exit(TAG_PREGNSLTxt);
            else
                exit(GroupCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure TimeActivityCode(ActivityCode: Code[10]): Code[10]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(ActivityCode);

        case ActivityCode of
            'B':
                exit(TAC_BTxt);
            'BDT':
                exit(TAC_BDTTxt);
            'BPT':
                exit(TAC_BPTTxt);
            'BUS':
                exit(TAC_BUSTxt);
            'VM':
                exit(TAC_VMTxt);
            'VP':
                exit(TAC_VPTxt);
            'V1':
                exit(TAC_V1Txt);
            'V2':
                exit(TAC_V2Txt);
            'G':
                exit(TAC_GTxt);
            'DB':
                exit(TAC_DBTxt);
            'DO':
                exit(TAC_DOTxt);
            'ZB':
                exit(TAC_ZBTxt);
            'K':
                exit(TAC_KTxt);
            'LCH':
                exit(TAC_LCHTxt);
            'N':
                exit(TAC_NTxt);
            'NB':
                exit(TAC_NBTxt);
            'NV':
                exit(TAC_NVTxt);
            'NZ':
                exit(TAC_NZTxt);
            'NN':
                exit(TAC_NNTxt);
            'NO':
                exit(TAC_NOTxt);
            'NP':
                exit(TAC_NPTxt);
            'NS':
                exit(TAC_NSTxt);
            'OV':
                exit(TAC_OVTxt);
            'OD':
                exit(TAC_ODTxt);
            'OJ':
                exit(TAC_OJTxt);
            'OJ1':
                exit(TAC_OJ1Txt);
            'OJ2':
                exit(TAC_OJ2Txt);
            'OJ3':
                exit(TAC_OJ3Txt);
            'OZ':
                exit(TAC_OZTxt);
            'OZCH':
                exit(TAC_OZCHTxt);
            'OT':
                exit(TAC_OTTxt);
            'PV':
                exit(TAC_PVTxt);
            'PK':
                exit(TAC_PKTxt);
            'PM':
                exit(TAC_PMTxt);
            'PR':
                exit(TAC_PRTxt);
            'R':
                exit(TAC_RTxt);
            'RV1':
                exit(TAC_RV1Txt);
            'RV2':
                exit(TAC_RV2Txt);
            'RP':
                exit(TAC_RPTxt);
            'S15':
                exit(TAC_S15Txt);
            'S20':
                exit(TAC_S20Txt);
            'T':
                exit(TAC_TTxt);
            'U':
                exit(TAC_UTxt);
            'UV':
                exit(TAC_UVTxt);
            'UD':
                exit(TAC_UDTxt);
            'YA':
                exit(TAC_YATxt);
            else
                exit(ActivityCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure DismissalReasonCode(DismissalReasonCode: Code[10]): Code[10]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(DismissalReasonCode);

        case DismissalReasonCode of
            'CH.58 P.2':
                exit(DRC_CH58P2Txt);
            'CH.72 P.1':
                exit(DRC_CH72P1Txt);
            'CH.72 P.2':
                exit(DRC_CH72P2Txt);
            'CH.73':
                exit(DRC_CH73Txt);
            'CH.75':
                exit(DRC_CH75Txt);
            'CH.78':
                exit(DRC_CH78Txt);
            'CH.80 P.1':
                exit(DRC_CH80P1Txt);
            'CH.80 P.2':
                exit(DRC_CH80P2Txt);
            'CH.81':
                exit(DRC_CH81Txt);
            'CH.83':
                exit(DRC_CH83Txt);
            'CH.84':
                exit(DRC_CH84Txt);
            else
                exit(DismissalReasonCode);
        end;
    end;

    [Scope('OnPrem')]
    procedure ElementFilter(ElementCodeFilter: Text[250]): Text[250]
    var
        PayrollElement: Record "Payroll Element";
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(ElementCodeFilter);

        PayrollElement.Reset;
        if PayrollElement.Find('+') then
            repeat
                ReplaceFilter(ElementCodeFilter, PayrollElement.Code, ElementCode(PayrollElement.Code));
            until PayrollElement.Next(-1) = 0;

        exit(ElementCodeFilter);
    end;

    local procedure ReplaceFilter(var ElementFilter: Text[250]; ENUText: Text[30]; RUSText: Text[30])
    var
        Pos: Integer;
    begin
        Pos := StrPos(ElementFilter, ENUText);
        if Pos > 0 then
            ElementFilter :=
              CopyStr(ElementFilter, 1, Pos - 1) +
              RUSText +
              CopyStr(ElementFilter, Pos + StrLen(ENUText));
    end;

    [Scope('OnPrem')]
    procedure ElementGroupFilter(ElementGroupCodeFilter: Text[250]): Text[250]
    var
        PayrollElementGroup: Record "Payroll Element Group";
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(ElementGroupCodeFilter);

        PayrollElementGroup.Reset;
        if PayrollElementGroup.Find('+') then
            repeat
                ReplaceGroupFilter(ElementGroupCodeFilter, PayrollElementGroup.Code, ElementGroup(PayrollElementGroup.Code));
            until PayrollElementGroup.Next(-1) = 0;

        exit(ElementGroupCodeFilter);
    end;

    local procedure ReplaceGroupFilter(var ElementGroupFilter: Text[250]; ENUText: Text[30]; RUSText: Text[30])
    var
        Pos: Integer;
    begin
        Pos := StrPos(ElementGroupFilter, ENUText);
        if Pos > 0 then
            ElementGroupFilter :=
              CopyStr(ElementGroupFilter, 1, Pos - 1) +
              RUSText +
              CopyStr(ElementGroupFilter, Pos + StrLen(ENUText));
    end;

    [Scope('OnPrem')]
    procedure GeneralDirectory(Name: Text[50]): Text[50]
    begin
        if (GlobalLanguage <> 1049) and (not TestMode) then
            exit(Name);

        case Name of
            'FAGCI':
                exit(GD_FAGCITxt);
            'FBS':
                exit(GD_FBSTxt);
            'FSS':
                exit(GD_FSSTxt);
            'NAVY':
                exit(GD_NAVYTxt);
            'ENGINEERING':
                exit(GD_ENGINEERINGTxt);
            'AF':
                exit(GD_AFTxt);
            'ENG-TECH':
                exit(GD_ENGTECHTxt);
            'POLIT':
                exit(GD_POLITTxt);
            'SAILOR':
                exit(GD_SAILORTxt);
            'LUBERCI':
                exit(GD_LUBERCITxt);
            'CARICINO':
                exit(GD_CARICINOTxt);
            'IZMAILOVO':
                exit(GD_IZMAILOVOTxt);
            'MOS SAD':
                exit(GD_MOSSADTxt);
            'MOS NWAD':
                exit(GD_MOSNWADTxt);
            'XI-SB':
                exit(GD_XISBTxt);
            'REGISTR':
                exit(GD_REGISTRTxt);
            'BIRTH':
                exit(GD_BIRTHTxt);
            'PERMAN':
                exit(GD_PERMANTxt);
            else
                exit(Name);
        end;
    end;
}

