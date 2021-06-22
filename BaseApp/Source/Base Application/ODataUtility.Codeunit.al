codeunit 6710 ODataUtility
{
    Permissions = TableData "Tenant Web Service OData" = rimd,
                  TableData "Tenant Web Service Columns" = rimd,
                  TableData "Tenant Web Service Filter" = rimd,
                  TableData "Tenant Web Service" = r;

    trigger OnRun()
    begin
    end;

    var
        ODataWizardTxt: Label 'Set Up Reporting Data';
        TypeHelper: Codeunit "Type Helper";
        WorksheetWriter: DotNet WorksheetWriter;
        WorkbookWriter: DotNet WorkbookWriter;
        ODataProtocolVersion: Option V3,V4;
        BalanceSheetHeadingTxt: Label 'Balance Sheet';
        BalanceSheetNameTxt: Label 'BalanceSheet', Locked = true;
        CompanyTxt: Label 'Company';
        CurrencyTxt: Label 'Currency';
        PrintedTxt: Label 'Printed';
        AsOfDateTxt: Label 'As of Date';
        DesciptionTxt: Label 'Description';
        BalanceTxt: Label 'Balance';
        PrintDollarLinesTxt: Label 'Print 0 Value Lines';
        SummaryTrialBalanceHeadingTxt: Label 'Summary Trial Balance';
        SummaryTrialBalanceNameTxt: Label 'SummaryTrialBalance', Locked = true;
        FromDateTxt: Label 'From Date';
        ToDateTxt: Label 'To Date';
        NoTxt: Label 'No.';
        NameTxt: Label 'Name';
        TotalDebitActivitiesTxt: Label 'Total Debit Activities';
        TotalCreditActivitiesTxt: Label 'Total Credit Activities';
        EndingBalanceTxt: Label 'Ending Balance';
        BeginningBalanceTxt: Label 'Beginning Balance';
        IncomeStatementHeadingTxt: Label 'Income Statement';
        IncomeStatementNameTxt: Label 'IncomeStatement', Locked = true;
        AccountNameTxt: Label 'Account Name';
        NetChangeTxt: Label 'Net Change';
        StatementOfRetainedEarningsHeadingTxt: Label 'Statement of Retained Earnings';
        StatementOfRetainedEarningsNameTxt: Label 'StatementOfRetainedEarnings', Locked = true;
        StartingDateTxt: Label 'Starting Date';
        EndingDateTxt: Label 'Ending Date';
        AgedAccountsPayableHeadingTxt: Label 'Aged Accounts Payable';
        AgedAccountsPayableNameTxt: Label 'AgedAccountsPayable', Locked = true;
        AgedAccountsReceivableHeaderTxt: Label 'Aged Accounts Receivable';
        AgedAccountsReceivableNameTxt: Label 'AgedAccountsReceivable', Locked = true;
        BalanceDueTxt: Label 'Balance Due';
        CurrentTxt: Label 'Current';
        UpTo30DaysTxt: Label 'Up to 30 Days';
        Days31To60Txt: Label '31-60 Days';
        Over60DaysTxt: Label 'Over 60 Days';
        AgedByTxt: Label 'Aged By';
        AgedAsOfDateTxt: Label 'Aged as of Date';
        DueDateTxt: Label 'Due Date';
        CashFlowHeadingTxt: Label 'Cash Flow Statement';
        CashFlowNameTxt: Label 'CashFlow', Locked = true;
        PeriodStartTxt: Label 'Period Start';
        PeriodEndTxt: Label 'Period End';
        DescriptionStaticTxt: Label 'Description', Locked = true;
        BalanceStaticTxt: Label 'Balance', Locked = true;
        NoStaticTxt: Label 'No.', Locked = true;
        NameStaticTxt: Label 'Name', Locked = true;
        BeginningBalanceStaticTxt: Label 'Beginning Balance', Locked = true;
        TotalDebitStaticTxt: Label 'Total Debit Activities', Locked = true;
        TotalCreditStaticTxt: Label 'Total Credit Activities', Locked = true;
        EndingBalanceStaticTxt: Label 'Ending Balance', Locked = true;
        AccountNameStaticTxt: Label 'Account Name', Locked = true;
        NetChangeStaticTxt: Label 'Net Change', Locked = true;
        BalanceDueStaticTxt: Label 'Balance Due', Locked = true;
        CurrentStaticTxt: Label 'Current', Locked = true;
        UpTo30StaticTxt: Label 'Up to 30 Days', Locked = true;
        Days31To60StaticTxt: Label '31-60 Days', Locked = true;
        Over60StaticTxt: Label 'Over 60 Days', Locked = true;
        WebServiceErr: Label 'The webservice %1 required for this excel report is missing.', Comment = '%1 - Web service name';

    [TryFunction]
    procedure GenerateSelectText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; var SelectTextParam: Text)
    var
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        TenantWebService: Record "Tenant Web Service";
        FirstColumn: Boolean;
    begin
        if TenantWebService.Get(ObjectTypeParam, ServiceNameParam) then begin
            FirstColumn := true;
            TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);

            if TenantWebServiceColumns.Find('-') then begin
                SelectTextParam := '$select=';
                repeat
                    if not FirstColumn then
                        SelectTextParam += ','
                    else
                        FirstColumn := false;

                    SelectTextParam += TenantWebServiceColumns."Field Name";
                until TenantWebServiceColumns.Next = 0;
            end;
        end;
    end;

    [TryFunction]
    procedure GenerateODataV3FilterText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; var FilterTextParam: Text)
    begin
        ODataProtocolVersion := ODataProtocolVersion::V3;
        FilterTextParam := GenerateFilterText(ServiceNameParam, ObjectTypeParam, CLIENTTYPE::OData);
        if FilterTextParam <> '' then
            FilterTextParam := StrSubstNo('$filter=%1', FilterTextParam);
    end;

    [TryFunction]
    procedure GenerateODataV4FilterText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; var FilterTextParam: Text)
    begin
        ODataProtocolVersion := ODataProtocolVersion::V4;
        FilterTextParam := GenerateFilterText(ServiceNameParam, ObjectTypeParam, CLIENTTYPE::ODataV4);
        if FilterTextParam <> '' then
            FilterTextParam := StrSubstNo('$filter=%1', FilterTextParam);
    end;

    local procedure GenerateFilterText(ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,"Codeunit",,,"Page","Query"; ClientType: ClientType): Text
    var
        TenantWebService: Record "Tenant Web Service";
        TableItemFilterTextDictionary: DotNet GenericDictionary2;
        FilterText: Text;
    begin
        if TenantWebService.Get(ObjectTypeParam, ServiceNameParam) then begin
            TableItemFilterTextDictionary := TableItemFilterTextDictionary.Dictionary;
            GetNAVFilters(TenantWebService, TableItemFilterTextDictionary);
            FilterText := CombineFiltersFromTables(TenantWebService, TableItemFilterTextDictionary, ClientType);
        end;

        exit(FilterText);
    end;

    procedure GenerateODataV3Url(ServiceRootUrlParam: Text; ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,,,,"Page","Query"): Text
    begin
        exit(GenerateUrl(ServiceRootUrlParam, ServiceNameParam, ObjectTypeParam, ODataProtocolVersion::V3));
    end;

    procedure GenerateODataV4Url(ServiceRootUrlParam: Text; ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,,,,"Page","Query"): Text
    begin
        exit(GenerateUrl(ServiceRootUrlParam, ServiceNameParam, ObjectTypeParam, ODataProtocolVersion::V4));
    end;

    local procedure GenerateUrl(ServiceRootUrlParam: Text; ServiceNameParam: Text; ObjectTypeParam: Option ,,,,,,,,"Page","Query"; ODataProtocolVersionParam: Option V3,V4): Text
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        WebServiceManagement: Codeunit "Web Service Management";
        ODataUrl: Text;
        SelectText: Text;
        FilterText: Text;
    begin
        if TenantWebService.Get(ObjectTypeParam, ServiceNameParam) then begin
            TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);

            if TenantWebServiceOData.FindFirst then begin
                SelectText := WebServiceManagement.GetODataSelectClause(TenantWebServiceOData);
                if ODataProtocolVersionParam = ODataProtocolVersionParam::V3 then
                    FilterText := WebServiceManagement.GetODataFilterClause(TenantWebServiceOData)
                else
                    FilterText := WebServiceManagement.GetODataV4FilterClause(TenantWebServiceOData);
            end;
        end;

        ODataUrl := BuildUrl(ServiceRootUrlParam, SelectText, FilterText);
        exit(ODataUrl);
    end;

    local procedure BuildUrl(ServiceRootUrlParam: Text; SelectTextParam: Text; FilterTextParam: Text): Text
    var
        ODataUrl: Text;
        preSelectTextConjunction: Text;
    begin
        if StrPos(ServiceRootUrlParam, '?tenant=') > 0 then
            preSelectTextConjunction := '&'
        else
            preSelectTextConjunction := '?';

        if (StrLen(SelectTextParam) > 0) and (StrLen(FilterTextParam) > 0) then
            ODataUrl := ServiceRootUrlParam + preSelectTextConjunction + SelectTextParam + '&' + FilterTextParam
        else
            if StrLen(SelectTextParam) > 0 then
                ODataUrl := ServiceRootUrlParam + preSelectTextConjunction + SelectTextParam
            else
                // FilterText is based on SelectText, so it doesn't make sense to have only the FilterText.
                ODataUrl := ServiceRootUrlParam;

        exit(ODataUrl);
    end;

    local procedure CombineFiltersFromTables(var TenantWebService: Record "Tenant Web Service"; TableItemFilterTextDictionaryParam: DotNet GenericDictionary2; ODataClientType: ClientType): Text
    var
        WebServiceManagement: Codeunit "Web Service Management";
        KeyValuePair: DotNet GenericKeyValuePair2;
        ODataFilterGenerator: DotNet ODataFilterGenerator;
        "Filter": Text;
        Conjunction: Text;
        DataItemFilterText: Text;
        FilterTextForSelectedColumns: Text;
    begin
        foreach KeyValuePair in TableItemFilterTextDictionaryParam do begin
            FilterTextForSelectedColumns := WebServiceManagement.RemoveUnselectedColumnsFromFilter(TenantWebService, KeyValuePair.Key, KeyValuePair.Value);
            case TenantWebService."Object Type" of
                TenantWebService."Object Type"::Page:
                    case ODataClientType of
                        CLIENTTYPE::OData:
                            DataItemFilterText := ODataFilterGenerator.CreateODataV3Filter(KeyValuePair.Key, FilterTextForSelectedColumns, 0);
                        CLIENTTYPE::ODataV4:
                            DataItemFilterText := ODataFilterGenerator.CreateODataV4Filter(KeyValuePair.Key, FilterTextForSelectedColumns, 0);
                    end;
                TenantWebService."Object Type"::Query:
                    case ODataClientType of
                        CLIENTTYPE::OData:
                            DataItemFilterText := ODataFilterGenerator.CreateODataV3Filter(KeyValuePair.Key, FilterTextForSelectedColumns,
                                TenantWebService."Object ID");
                        CLIENTTYPE::ODataV4:
                            DataItemFilterText := ODataFilterGenerator.CreateODataV4Filter(KeyValuePair.Key, FilterTextForSelectedColumns,
                                TenantWebService."Object ID");
                    end;
            end;
            Filter := StrSubstNo('%1%2%3', Filter, Conjunction, DataItemFilterText);
            Conjunction := ' and ';
        end;
        exit(Filter);
    end;

    [TryFunction]
    local procedure FindColumnsFromNAVFilters(var TenantWebService: Record "Tenant Web Service"; TableItemFilterTextDictionaryParam: DotNet GenericDictionary2; var ColumnListParam: DotNet GenericList1)
    var
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        FieldTable: Record "Field";
        Regex: DotNet Regex;
        LocalFilterSegments: DotNet Array;
        TempString1: DotNet String;
        TempString2: DotNet String;
        KeyValuePair: DotNet GenericKeyValuePair2;
        LocalFilterText: Text;
        I: Integer;
        Column: Text;
        IndexOfKeyStart: Integer;
        IndexOfValueEnd: Integer;
    begin
        // SORTING(No.) WHERE(No=FILTER(01121212..01454545|31669966),Balance Due=FILTER(>0))

        foreach KeyValuePair in TableItemFilterTextDictionaryParam do begin
            LocalFilterText := DelStr(KeyValuePair.Value, 1, StrPos(KeyValuePair.Value, 'WHERE') + 5);  // becomes No=FILTER(01121212..01454545|31669966),Balance Due=FILTER(>0))
            LocalFilterText := DelStr(LocalFilterText, StrLen(LocalFilterText), 1); // remove ), becomes No=FILTER(01121212..01454545|31669966),Balance Due=FILTER(>0)
            LocalFilterSegments := Regex.Split(LocalFilterText, '=FILTER'); // No   (01121212..01454545|31669966),Balance Due   (>0)

            // Break all the filters into key value pairs.
            for I := 0 to LocalFilterSegments.Length - 2 do begin
                TempString1 := LocalFilterSegments.GetValue(I);
                TempString2 := LocalFilterSegments.GetValue(I + 1);
                IndexOfKeyStart := TempString1.LastIndexOf(',');
                IndexOfValueEnd := TempString2.LastIndexOf(',');

                // Start index of the key is either at the beginning or right after the comma.
                if IndexOfKeyStart > 0 then
                    IndexOfKeyStart := IndexOfKeyStart + 1
                else
                    IndexOfKeyStart := 0;

                // End index of the value is either right before the comma or at the end.  Make sure we don't confuse commas in last filter value.
                if (IndexOfValueEnd < 0) or (I = LocalFilterSegments.Length - 2) then
                    IndexOfValueEnd := TempString2.Length;

                Column := TempString1.Substring(IndexOfKeyStart, TempString1.Length - IndexOfKeyStart);

                // Add to the list if the field is in the dataset.
                FieldTable.SetRange(TableNo, KeyValuePair.Key);
                FieldTable.SetFilter(ObsoleteState, '<>%1', FieldTable.ObsoleteState::Removed);
                FieldTable.SetRange("Field Caption", Column);
                if FieldTable.FindFirst then begin
                    TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
                    TenantWebServiceColumns.SetRange("Data Item", KeyValuePair.Key);
                    TenantWebServiceColumns.SetRange("Field Number", FieldTable."No.");
                    if TenantWebServiceColumns.FindFirst then
                        ColumnListParam.Add(Column);
                end;
            end;
        end;
    end;

    local procedure GetNAVFilters(var TenantWebService: Record "Tenant Web Service"; var TableItemFilterTextDictionaryParam: DotNet GenericDictionary2)
    var
        TenantWebServiceFilter: Record "Tenant Web Service Filter";
        WebServiceManagement: Codeunit "Web Service Management";
        FilterText: Text;
    begin
        TenantWebServiceFilter.SetRange(TenantWebServiceID, TenantWebService.RecordId());
        if TenantWebServiceFilter.Find('-') then begin
            repeat
                FilterText := WebServiceManagement.GetTenantWebServiceFilter(TenantWebServiceFilter);
                if StrLen(FilterText) > 0 then
                    TableItemFilterTextDictionaryParam.Add(TenantWebServiceFilter."Data Item", FilterText);
            until TenantWebServiceFilter.Next() = 0;
        end;
    end;

    procedure ConvertNavFieldNameToOdataName(NavFieldName: Text): Text
    begin
        exit(ExternalizeODataObjectName(NavFieldName));
    end;

    [Scope('OnPrem')]
    procedure GetColumnsFromFilter(var TenantWebService: Record "Tenant Web Service"; FilterText: Text; var ColumnList: DotNet GenericList1)
    var
        TableItemFilterTextDictionary: DotNet GenericDictionary2;
    begin
        TableItemFilterTextDictionary := TableItemFilterTextDictionary.Dictionary;
        TableItemFilterTextDictionary.Add(1, FilterText);
        FindColumnsFromNAVFilters(TenantWebService, TableItemFilterTextDictionary, ColumnList);
    end;

    [EventSubscriber(ObjectType::Codeunit, 2, 'OnCompanyInitialize', '', false, false)]
    procedure CreateAssistedSetup()
    var
        AssistedSetup: Codeunit "Assisted Setup";
        Info: ModuleInfo;
        AssistedSetupGroup: Enum "Assisted Setup Group";
    begin
        NavApp.GetCurrentModuleInfo(Info);
        AssistedSetup.Add(Info.Id(), PAGE::"OData Setup Wizard", ODataWizardTxt, AssistedSetupGroup::GettingStarted);
    end;

    local procedure CreateWorksheetWebService(PageCaption: Text[240]; PageId: Text)
    var
        TenantWebService: Record "Tenant Web Service";
        ObjectId: Integer;
        ServiceName: Text[240];
    begin
        ServiceName := PageCaption;
        if AssertServiceNameBeginsWithADigit(PageCaption) then
            ServiceName := 'WS' + PageCaption;
        if not TenantWebService.Get(TenantWebService."Object Type"::Page, ServiceName) then begin
            TenantWebService.Init();
            TenantWebService."Object Type" := TenantWebService."Object Type"::Page;
            Evaluate(ObjectId, CopyStr(PageId, 5));
            TenantWebService."Object ID" := ObjectId;
            TenantWebService."Service Name" := ServiceName;
            TenantWebService.Published := true;
            TenantWebService.Insert(true);
        end;
    end;

    local procedure AssertServiceNameBeginsWithADigit(ServiceName: text[250]): Boolean
    begin
        if ServiceName[1] in ['0' .. '9'] then
            exit(true);
        exit(false);
    end;

    procedure EditJournalWorksheetInExcel(PageCaption: Text[240]; PageId: Text; JournalBatchName: Text; JournalTemplateName: Text)
    var
        "Filter": Text;
    begin
        CreateWorksheetWebService(PageCaption, PageId);

        Filter := StrSubstNo('Journal_Batch_Name eq ''%1'' and Journal_Template_Name eq ''%2''', JournalBatchName, JournalTemplateName);
        OnEditInExcel(PageCaption, Filter);
    end;

    procedure EditWorksheetInExcel(PageCaption: Text[240]; PageId: Text; "Filter": Text)
    begin
        CreateWorksheetWebService(PageCaption, PageId);
        OnEditInExcel(PageCaption, Filter);
    end;

    [Scope('OnPrem')]
    procedure GenerateExcelWorkBook(ObjectTypeParm: Option ,,,,,"Codeunit",,,"Page","Query"; ServiceNameParm: Text; ShowDialogParm: Boolean; SearchFilter: Text)
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
    begin
        if not TenantWebService.Get(ObjectTypeParm, ServiceNameParm) then
            exit;

        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        TenantWebServiceColumns.FindFirst;

        GenerateExcelWorkBookWithColumns(ObjectTypeParm, ServiceNameParm, ShowDialogParm, TenantWebServiceColumns, SearchFilter)
    end;

    [Scope('OnPrem')]
    procedure GenerateExcelWorkBookWithColumns(ObjectTypeParm: Option ,,,,,"Codeunit",,,"Page","Query"; ServiceNameParm: Text; ShowDialogParm: Boolean; var TenantWebServiceColumns: Record "Tenant Web Service Columns"; SearchFilter: Text)
    var
        TenantWebService: Record "Tenant Web Service";
        TempBlob: Codeunit "Temp Blob";
        FileManagement: Codeunit "File Management";
        DataEntityExportInfo: DotNet DataEntityExportInfo;
        DataEntityExportGenerator: DotNet DataEntityExportGenerator;
        NvOutStream: OutStream;
        FileName: Text;
    begin
        if not TenantWebService.Get(ObjectTypeParm, ServiceNameParm) then
            exit;

        DataEntityExportInfo := DataEntityExportInfo.DataEntityExportInfo;
        CreateDataEntityExportInfo(TenantWebService, DataEntityExportInfo, TenantWebServiceColumns, SearchFilter);

        DataEntityExportGenerator := DataEntityExportGenerator.DataEntityExportGenerator;
        TempBlob.CreateOutStream(NvOutStream);
        DataEntityExportGenerator.GenerateWorkbook(DataEntityExportInfo, NvOutStream);
        FileName := TenantWebService."Service Name" + '.xlsx';
        FileManagement.BLOBExport(TempBlob, FileName, ShowDialogParm);
    end;

    [Scope('OnPrem')]
    procedure GenerateExcelTemplateWorkBook(ObjectTypeParm: Option ,,,,,"Codeunit",,,"Page","Query"; ServiceNameParm: Text[50]; ShowDialogParm: Boolean; StatementType: Option BalanceSheet,SummaryTrialBalance,CashFlowStatement,StatementOfRetainedEarnings,AgedAccountsReceivable,AgedAccountsPayable,IncomeStatement)
    var
        TenantWebService: Record "Tenant Web Service";
        MediaResources: Record "Media Resources";
        EnvironmentInfo: Codeunit "Environment Information";
        FileManagement: Codeunit "File Management";
        AzureADTenant: Codeunit "Azure AD Tenant";
        TempBlob: Codeunit "Temp Blob";
        OfficeAppInfo: DotNet OfficeAppInfo;
        WorkbookSettingsManager: DotNet WorkbookSettingsManager;
        SettingsObject: DotNet DynamicsExtensionSettings;
        NvOutStream: OutStream;
        NvInStream: InStream;
        HostName: Text;
        FileName: Text;
        TempFileName: Text[60];
    begin
        if not TenantWebService.Get(ObjectTypeParm, ServiceNameParm) then
            Error(WebServiceErr, ServiceNameParm);

        OfficeAppInfo := OfficeAppInfo.OfficeAppInfo;
        OfficeAppInfo.Id := 'WA104379629';
        OfficeAppInfo.Store := 'en-US';
        OfficeAppInfo.StoreType := 'OMEX';
        OfficeAppInfo.Version := '1.3.0.0';

        HostName := GetHostName;
        if StrPos(HostName, '?') <> 0 then
            HostName := CopyStr(HostName, 1, StrPos(HostName, '?') - 1);

        TempFileName := ServiceNameParm + '.xltm';
        if not MediaResources.Get(TempFileName) then
            exit;

        MediaResources.CalcFields(Blob);
        MediaResources.Blob.CreateInStream(NvInStream);

        TempBlob.CreateOutStream(NvOutStream);
        CopyStream(NvOutStream, NvInStream);

        // Collect data for template translations to match company generated for
        WorkbookWriter := WorkbookWriter.Open(NvOutStream);
        WorksheetWriter := WorkbookWriter.FirstWorksheet;

        case StatementType of
            StatementType::BalanceSheet:
                AddBalanceSheetCellValues;
            StatementType::SummaryTrialBalance:
                AddSummaryTrialBalancetCellValues;
            StatementType::AgedAccountsPayable:
                AddAgedAccountsPayableCellValues;
            StatementType::AgedAccountsReceivable:
                AddAgedAccountsReceivableCellValues;
            StatementType::CashFlowStatement:
                AddCashFlowStatementCellValues;
            StatementType::IncomeStatement:
                AddIncomeStatementCellValues;
            StatementType::StatementOfRetainedEarnings:
                AddStatementOfRetainedEarningsCellValues;
        end;

        WorkbookSettingsManager := WorkbookSettingsManager.WorkbookSettingsManager(WorkbookWriter.Document);

        SettingsObject := SettingsObject.DynamicsExtensionSettings;
        WorkbookSettingsManager.SettingsObject.Headers.Clear;
        if EnvironmentInfo.IsSaaS() then
            WorkbookSettingsManager.SettingsObject.Headers.Add('BCEnvironment', EnvironmentInfo.GetEnvironmentName());
        WorkbookSettingsManager.SettingsObject.Headers.Add('Company', TenantWebService.CurrentCompany);
        WorkbookSettingsManager.SetAppInfo(OfficeAppInfo);
        WorkbookSettingsManager.SetHostName(HostName);
        WorkbookSettingsManager.SetAuthenticationTenant(AzureADTenant.GetAadTenantId);
        WorkbookSettingsManager.SetLanguage(TypeHelper.LanguageIDToCultureName(WindowsLanguage));
        WorkbookWriter.Close;

        FileName := TenantWebService."Service Name" + '.xltm';
        FileManagement.BLOBExport(TempBlob, FileName, ShowDialogParm);
    end;

    local procedure GetConjunctionString(var localFilterSegments: DotNet Array; var ConjunctionStringParam: Text; var IndexParam: Integer)
    begin
        if IndexParam < localFilterSegments.Length then begin
            ConjunctionStringParam := localFilterSegments.GetValue(IndexParam);
            IndexParam += 1;
        end else
            ConjunctionStringParam := '';
    end;

    local procedure GetNextFieldString(var localFilterSegments: DotNet Array; var NextFieldStringParam: Text; var IndexParam: Integer)
    begin
        if IndexParam < localFilterSegments.Length then begin
            NextFieldStringParam := localFilterSegments.GetValue(IndexParam);
            IndexParam += 1;
        end else
            NextFieldStringParam := '';
    end;

    local procedure TrimFilterClause(var FilterClauseParam: Text)
    begin
        if StrPos(FilterClauseParam, 'filter=') <> 0 then
            FilterClauseParam := DelStr(FilterClauseParam, 1, StrPos(FilterClauseParam, 'filter=') + 6);

        // becomes  ((No ge '01121212' and No le '01445544') or No eq '10000') and ((Name eq 'bob') and Name eq 'frank')
        FilterClauseParam := DelChr(FilterClauseParam, '<', '(');
        FilterClauseParam := DelChr(FilterClauseParam, '>', ')');
        // becomes  (No ge '01121212' and No le '01445544') or No eq '10000') and ((Name eq 'bob') and Name eq 'frank'
    end;

    local procedure GetEndPointAndCreateWorkbook(ServiceName: Text[240]; ODataFilter: Text; SearchFilter: Text)
    var
        TenantWebService: Record "Tenant Web Service";
        TenantWebServiceOData: Record "Tenant Web Service OData";
        TenantWebServiceColumns: Record "Tenant Web Service Columns";
        TempTenantWebServiceColumns: Record "Tenant Web Service Columns" temporary;
        WebServiceManagement: Codeunit "Web Service Management";
        ColumnDictionary: DotNet GenericDictionary2;
        SourceTableText: Text;
        SavedSelectText: Text;
        DefaultSelectText: Text;
        OldFilter: Text;
        TableNo: Integer;
        UseTempColumns: Boolean;
    begin
        ColumnDictionary := ColumnDictionary.Dictionary;

        if not TenantWebService.Get(TenantWebService."Object Type"::Page, ServiceName) then
            exit;

        TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);

        // Get the default $select text
        InitSelectedColumns(TenantWebService, ColumnDictionary, SourceTableText);
        Evaluate(TableNo, SourceTableText);
        DefaultSelectText := GetDefaultSelectText(ColumnDictionary);
        SavedSelectText := WebServiceManagement.GetODataSelectClause(TenantWebServiceOData);

        // If we don't have an endpoint - we need a new endpoint
        if not TenantWebServiceOData.FindFirst then begin
            CreateEndPoint(TenantWebService, ColumnDictionary, DefaultSelectText, TenantWebServiceColumns);
            TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
            TenantWebServiceOData.FindFirst;
        end else begin
            // If we have a select text mismatch - set the select text for this operation and use a temp column record
            if SavedSelectText <> DefaultSelectText then begin
                WebServiceManagement.InsertSelectedColumns(TenantWebService, ColumnDictionary, TempTenantWebServiceColumns, TableNo);
                TempTenantWebServiceColumns.Modify(true);
                TempTenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
                TempTenantWebServiceColumns.FindFirst;
                WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, DefaultSelectText);
                UseTempColumns := true;
            end;
            // Save the filter to restore later
            OldFilter := WebServiceManagement.GetODataFilterClause(TenantWebServiceOData);
        end;

        // This record should now exist after creating the endpoint.
        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        TenantWebServiceColumns.FindFirst;

        WebServiceManagement.SetODataV4FilterClause(TenantWebServiceOData, ODataFilter);
        TenantWebServiceOData.Modify(true);

        if UseTempColumns then
            GenerateExcelWorkBookWithColumns(TenantWebService."Object Type", ServiceName, true, TempTenantWebServiceColumns, SearchFilter)
        else
            GenerateExcelWorkBookWithColumns(TenantWebService."Object Type", ServiceName, true, TenantWebServiceColumns, SearchFilter);

        // Restore the filters and columns.
        TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        TenantWebServiceOData.FindFirst;
        WebServiceManagement.SetODataV4FilterClause(TenantWebServiceOData, OldFilter);
        WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, SavedSelectText);
        TenantWebServiceOData.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateDataEntityExportInfo(var TenantWebService: Record "Tenant Web Service"; var DataEntityExportInfoParam: DotNet DataEntityExportInfo; var TenantWebServiceColumns: Record "Tenant Web Service Columns"; SearchFilter: Text)
    var
        TenantWebServiceOData: Record "Tenant Web Service OData";
        WebServiceManagement: Codeunit "Web Service Management";
        EnvironmentInfo: Codeunit "Environment Information";
        AzureADTenant: Codeunit "Azure AD Tenant";
        ConnectionInfo: DotNet ConnectionInfo;
        OfficeAppInfo: DotNet OfficeAppInfo;
        DataEntityInfo: DotNet DataEntityInfo;
        BindingInfo: DotNet BindingInfo;
        FieldInfo: DotNet "Office.FieldInfo";
        FieldFilterCollectionNode: DotNet FilterCollectionNode;
        FieldFilterCollectionNode2: DotNet FilterCollectionNode;
        EntityFilterCollectionNode: DotNet FilterCollectionNode;
        AuthenticationOverrides: DotNet AuthenticationOverrides;
        FilterClause: Text;
        HostName: Text;
        ServiceName: Text;
        FieldFilterCounter: Integer;
        Inserted: Boolean;
    begin
        OfficeAppInfo := OfficeAppInfo.OfficeAppInfo;
        OfficeAppInfo.Id := 'WA104379629';
        OfficeAppInfo.Store := 'en-US'; // todo US store only?
        OfficeAppInfo.StoreType := 'OMEX';
        OfficeAppInfo.Version := '1.3.0.0';

        AuthenticationOverrides := AuthenticationOverrides.AuthenticationOverrides;
        AuthenticationOverrides.Tenant := AzureADTenant.GetAadTenantId;

        DataEntityExportInfoParam := DataEntityExportInfoParam.DataEntityExportInfo;
        DataEntityExportInfoParam.AppReference := OfficeAppInfo;
        DataEntityExportInfoParam.Authentication := AuthenticationOverrides;

        ConnectionInfo := ConnectionInfo.ConnectionInfo;
        HostName := GetHostName;

        if StrPos(HostName, '?') <> 0 then
            HostName := CopyStr(HostName, 1, StrPos(HostName, '?') - 1);
        ConnectionInfo.HostName := HostName;

        DataEntityExportInfoParam.Connection := ConnectionInfo;
        DataEntityExportInfoParam.Language := TypeHelper.LanguageIDToCultureName(WindowsLanguage); // todo get language
        DataEntityExportInfoParam.EnableDesign := true;
        DataEntityExportInfoParam.RefreshOnOpen := true;
        if EnvironmentInfo.IsSaaS() then
            DataEntityExportInfoParam.Headers.Add('BCEnvironment', EnvironmentInfo.GetEnvironmentName());
        DataEntityExportInfoParam.Headers.Add('Company', TenantWebService.CurrentCompany);
        if SearchFilter <> '' then
            DataEntityExportInfoParam.Headers.Add('pageSearchString', DelChr(SearchFilter, '=', '@*'));
        DataEntityInfo := DataEntityInfo.DataEntityInfo;
        ServiceName := ExternalizeODataObjectName(TenantWebService."Service Name");
        DataEntityInfo.Name := ServiceName;
        DataEntityInfo.PublicName := ServiceName;
        DataEntityExportInfoParam.Entities.Add(DataEntityInfo);

        BindingInfo := BindingInfo.BindingInfo;
        BindingInfo.EntityName := DataEntityInfo.Name;

        DataEntityExportInfoParam.Bindings.Add(BindingInfo);

        TenantWebServiceOData.Init();
        TenantWebServiceOData.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        TenantWebServiceOData.FindFirst;

        TenantWebServiceColumns.Init();
        TenantWebServiceColumns.SetRange(TenantWebServiceID, TenantWebService.RecordId);
        FilterClause := WebServiceManagement.GetODataV4FilterClause(TenantWebServiceOData);

        EntityFilterCollectionNode := EntityFilterCollectionNode.FilterCollectionNode;  // One filter collection node for entire entity
        if TenantWebServiceColumns.FindSet then begin
            repeat
                FieldInfo := FieldInfo.FieldInfo;
                FieldInfo.Name := TenantWebServiceColumns."Field Name";
                FieldInfo.Label := TenantWebServiceColumns."Field Name";
                BindingInfo.Fields.Add(FieldInfo);

                Inserted := InsertDataIntoFilterCollectionNode(TenantWebServiceColumns."Field Name", GetFieldType(TenantWebServiceColumns),
                    FilterClause, EntityFilterCollectionNode, FieldFilterCollectionNode, FieldFilterCollectionNode2);

                if Inserted then
                    FieldFilterCounter += 1;

                if FieldFilterCounter > 1 then
                    EntityFilterCollectionNode.Operator('and');  // All fields are anded together

            until TenantWebServiceColumns.Next = 0;
            AddFieldNodeToEntityNode(FieldFilterCollectionNode, FieldFilterCollectionNode2, EntityFilterCollectionNode);
        end;

        DataEntityInfo.Filter(EntityFilterCollectionNode);
    end;

    local procedure InsertDataIntoFilterCollectionNode(FieldName: Text; FieldType: Text; FilterClause: Text; var EntityFilterCollectionNode: DotNet FilterCollectionNode; var FieldFilterCollectionNode: DotNet FilterCollectionNode; var FieldFilterCollectionNode2: DotNet FilterCollectionNode): Boolean
    var
        FilterBinaryNode: DotNet FilterBinaryNode;
        FilterLeftOperand: DotNet FilterLeftOperand;
        ValueString: DotNet String;
        Regex: DotNet Regex;
        FilterSegments: DotNet Array;
        ConjunctionString: Text;
        OldConjunctionString: Text;
        NextFieldString: Text;
        Index: Integer;
        NumberOfCharsTrimmed: Integer;
        TrimPos: Integer;
        FilterCreated: Boolean;
    begin
        // New column, if the previous row had data, add it entity filter collection
        AddFieldNodeToEntityNode(FieldFilterCollectionNode, FieldFilterCollectionNode2, EntityFilterCollectionNode);

        TrimPos := 0;
        Index := 1;
        OldConjunctionString := '';
        // $filter=((No ge '01121212' and No le '01445544') or No eq '10000') and ((Name eq 'bo b') and Name eq 'fra nk')
        if FilterClause <> '' then begin
            TrimFilterClause(FilterClause);

            if Regex.IsMatch(FilterClause, StrSubstNo('\b%1\b', FieldName)) then begin
                FilterClause := CopyStr(FilterClause, StrPos(FilterClause, FieldName + ' '));

                while FilterClause <> '' do begin
                    FilterCreated := true;
                    FilterBinaryNode := FilterBinaryNode.FilterBinaryNode;
                    FilterLeftOperand := FilterLeftOperand.FilterLeftOperand;

                    FilterLeftOperand.Field(FieldName);
                    FilterLeftOperand.Type(FieldType);

                    FilterBinaryNode.Left := FilterLeftOperand;
                    FilterSegments := Regex.Split(FilterClause, ' ');

                    FilterBinaryNode.Operator(FilterSegments.GetValue(1));
                    ValueString := FilterSegments.GetValue(2);
                    Index := 3;

                    NumberOfCharsTrimmed := ConcatValueStringPortions(ValueString, FilterSegments, Index);

                    FilterBinaryNode.Right(ValueString);

                    TrimPos := StrPos(FilterClause, ValueString) + StrLen(ValueString) + NumberOfCharsTrimmed;

                    GetConjunctionString(FilterSegments, ConjunctionString, Index);

                    GetNextFieldString(FilterSegments, NextFieldString, Index);

                    TrimPos := TrimPos + StrLen(ConjunctionString) + StrLen(NextFieldString);

                    if (NextFieldString = '') or (NextFieldString = FieldName) then begin
                        if (OldConjunctionString <> '') and (OldConjunctionString <> ConjunctionString) then begin
                            if IsNull(FieldFilterCollectionNode2) then begin
                                FieldFilterCollectionNode2 := FieldFilterCollectionNode2.FilterCollectionNode;
                                FieldFilterCollectionNode2.Operator(ConjunctionString);
                            end;

                            FieldFilterCollectionNode.Collection.Add(FilterBinaryNode);
                            if OldConjunctionString <> '' then
                                FieldFilterCollectionNode.Operator(OldConjunctionString);

                            FieldFilterCollectionNode2.Collection.Add(FieldFilterCollectionNode);

                            Clear(FieldFilterCollectionNode);
                        end else begin
                            if IsNull(FieldFilterCollectionNode) then
                                FieldFilterCollectionNode := FieldFilterCollectionNode.FilterCollectionNode;

                            FieldFilterCollectionNode.Collection.Add(FilterBinaryNode);
                            FieldFilterCollectionNode.Operator(OldConjunctionString)
                        end
                    end else begin
                        if IsNull(FieldFilterCollectionNode2) then
                            FieldFilterCollectionNode2 := FieldFilterCollectionNode2.FilterCollectionNode;

                        if IsNull(FieldFilterCollectionNode) then
                            FieldFilterCollectionNode := FieldFilterCollectionNode.FilterCollectionNode;

                        FieldFilterCollectionNode.Collection.Add(FilterBinaryNode);
                        FieldFilterCollectionNode.Operator(OldConjunctionString);

                        FieldFilterCollectionNode2.Collection.Add(FieldFilterCollectionNode);

                        Clear(FieldFilterCollectionNode);

                        FilterClause := ''; // the FilterClause is exhausted for this field
                    end;

                    OldConjunctionString := ConjunctionString;

                    FilterClause := CopyStr(FilterClause, TrimPos); // remove that portion that has been processed.
                end;
            end;
        end;
        exit(FilterCreated);
    end;

    local procedure ConcatValueStringPortions(var ValueStringParam: DotNet String; var FilterSegmentsParam: DotNet Array; var IndexParm: Integer): Integer
    var
        ValueStringPortion: DotNet String;
        LastPosition: Integer;
        FirstPosition: Integer;
        SingleTick: Char;
        StrLenAfterTrim: Integer;
        StrLenBeforeTrim: Integer;
    begin
        SingleTick := 39;

        FirstPosition := ValueStringParam.IndexOf(SingleTick);
        LastPosition := ValueStringParam.LastIndexOf(SingleTick);

        // The valueString might have been spit earlier if it had an embedded ' ', stick it back together
        if (FirstPosition = 0) and (FirstPosition = LastPosition) then begin
            repeat
                ValueStringPortion := FilterSegmentsParam.GetValue(IndexParm);
                ValueStringParam := ValueStringParam.Concat(ValueStringParam, ' ');
                ValueStringParam := ValueStringParam.Concat(ValueStringParam, ValueStringPortion);
                ValueStringPortion := FilterSegmentsParam.GetValue(IndexParm);
                IndexParm += 1;
            until ValueStringPortion.LastIndexOf(SingleTick) > 0;
        end;

        // Now that the string has been put back together if needed, remove leading and trailing SingleTick
        // as the excel addin will apply them.
        FirstPosition := ValueStringParam.IndexOf(SingleTick);

        StrLenBeforeTrim := StrLen(ValueStringParam);
        if FirstPosition = 0 then begin
            ValueStringParam := DelStr(ValueStringParam, 1, 1);
            LastPosition := ValueStringParam.LastIndexOf(SingleTick);
            if LastPosition > 0 then begin
                ValueStringParam := DelChr(ValueStringParam, '>', ')'); // Remove any trailing ')'
                ValueStringParam := DelStr(ValueStringParam, ValueStringParam.Length, 1);
            end;
        end;

        StrLenAfterTrim := StrLen(ValueStringParam);
        exit(StrLenBeforeTrim - StrLenAfterTrim);
    end;

    local procedure GetFieldType(var TenantWebServiceColumnsParam: Record "Tenant Web Service Columns"): Text
    var
        FieldTable: Record "Field";
    begin
        FieldTable.SetRange(TableNo, TenantWebServiceColumnsParam."Data Item");
        FieldTable.SetRange("No.", TenantWebServiceColumnsParam."Field Number");
        if FieldTable.FindFirst then
            case FieldTable.Type of
                FieldTable.Type::Text, FieldTable.Type::Code, FieldTable.Type::OemCode, FieldTable.Type::OemText, FieldTable.Type::Option:
                    exit('Edm.String');
                FieldTable.Type::BigInteger, FieldTable.Type::Integer:
                    exit('Edm.Int32');
                FieldTable.Type::Decimal:
                    exit('Edm.Decimal');
                FieldTable.Type::Date, FieldTable.Type::DateTime, FieldTable.Type::Time:
                    exit('Edm.DateTimeOffset');
                FieldTable.Type::Boolean:
                    exit('Edm.Boolean');
            end;
    end;

    local procedure AddFieldNodeToEntityNode(var FieldFilterCollectionNodeParam: DotNet FilterCollectionNode; var FieldFilterCollectionNode2Param: DotNet FilterCollectionNode; var EntityFilterCollectionNodeParam: DotNet FilterCollectionNode)
    begin
        if not IsNull(FieldFilterCollectionNode2Param) then begin
            EntityFilterCollectionNodeParam.Collection.Add(FieldFilterCollectionNode2Param);
            Clear(FieldFilterCollectionNode2Param);
        end;

        if not IsNull(FieldFilterCollectionNodeParam) then begin
            EntityFilterCollectionNodeParam.Collection.Add(FieldFilterCollectionNodeParam);
            Clear(FieldFilterCollectionNodeParam);
        end;
    end;

    local procedure InitSelectedColumns(var TenantWebService: Record "Tenant Web Service"; ColumnDictionary: DotNet GenericDictionary2; var SourceTableText: Text)
    begin
        InitColumnsForPage(TenantWebService, ColumnDictionary, SourceTableText);
    end;

    local procedure InitColumnsForPage(var TenantWebService: Record "Tenant Web Service"; ColumnDictionary: DotNet GenericDictionary2; var SourceTableTextParam: Text)
    var
        FieldsTable: Record "Field";
        PageControlField: Record "Page Control Field";
        FieldNameText: Text;
    begin
        PageControlField.SetRange(PageNo, TenantWebService."Object ID");
        PageControlField.SetCurrentKey(Sequence);
        PageControlField.SetAscending(Sequence, true);
        if PageControlField.FindSet then
            repeat
                SourceTableTextParam := Format(PageControlField.TableNo);

                if FieldsTable.Get(PageControlField.TableNo, PageControlField.FieldNo) then
                    if not ColumnDictionary.ContainsKey(FieldsTable."No.") then begin
                        // Convert to OData compatible name.
                        FieldNameText := ConvertNavFieldNameToOdataName(PageControlField.ControlName);
                        ColumnDictionary.Add(FieldsTable."No.", FieldNameText);
                    end;
            until PageControlField.Next = 0;

        EnsureKeysInSelect(SourceTableTextParam, ColumnDictionary);
    end;

    local procedure EnsureKeysInSelect(SourceTableTextParam: Text; ColumnDictionary: DotNet GenericDictionary2)
    var
        RecRef: RecordRef;
        VarKeyRef: KeyRef;
        VarFieldRef: FieldRef;
        KeysText: DotNet String;
        SourceTableId: Integer;
        i: Integer;
    begin
        Evaluate(SourceTableId, SourceTableTextParam);

        RecRef.Open(SourceTableId);
        VarKeyRef := RecRef.KeyIndex(1);
        for i := 1 to VarKeyRef.FieldCount do begin
            VarFieldRef := VarKeyRef.FieldIndex(i);
            KeysText := ConvertNavFieldNameToOdataName(VarFieldRef.Name);

            if not ColumnDictionary.ContainsKey(VarFieldRef.Number) then
                ColumnDictionary.Add(VarFieldRef.Number, KeysText);
        end;
    end;

    local procedure InsertODataRecord(var TenantWebService: Record "Tenant Web Service"; SelectText: Text)
    var
        TenantWebServiceOData: Record "Tenant Web Service OData";
        WebServiceManagement: Codeunit "Web Service Management";
    begin
        TenantWebServiceOData.Init();
        TenantWebServiceOData.Validate(TenantWebServiceID, TenantWebService.RecordId);
        WebServiceManagement.SetODataSelectClause(TenantWebServiceOData, SelectText);
        TenantWebServiceOData.Insert(true);
    end;

    local procedure GetDefaultSelectText(var ColumnDictionary: DotNet GenericDictionary2): Text
    var
        keyValuePair: DotNet GenericKeyValuePair2;
        FirstColumn: Boolean;
        SelectTextParam: Text;
    begin
        FirstColumn := true;
        SelectTextParam := '$select=';
        foreach keyValuePair in ColumnDictionary do begin
            if not FirstColumn then
                SelectTextParam += ','
            else
                FirstColumn := false;

            SelectTextParam += CopyStr(keyValuePair.Value, 1);
        end;

        exit(SelectTextParam);
    end;

    local procedure CreateEndPoint(var TenantWebService: Record "Tenant Web Service"; var ColumnDictionary: DotNet GenericDictionary2; SelectQueryParam: Text; var TenantWebServiceColumns: Record "Tenant Web Service Columns")
    var
        WebServiceManagement: Codeunit "Web Service Management";
        SourceTableText: Text;
        TableNo: Integer;
    begin
        InitSelectedColumns(TenantWebService, ColumnDictionary, SourceTableText);
        Evaluate(TableNo, SourceTableText);
        WebServiceManagement.InsertSelectedColumns(TenantWebService, ColumnDictionary, TenantWebServiceColumns, TableNo);
        InsertODataRecord(TenantWebService, SelectQueryParam);
    end;

    [EventSubscriber(ObjectType::Codeunit, 6710, 'OnEditInExcel', '', false, false)]
    local procedure EditInExcel(ServiceName: Text[240]; ODataFilter: Text)
    begin
        OnEditInExcelWithSearch(ServiceName, ODataFilter, '')
    end;

    [EventSubscriber(ObjectType::Codeunit, 6710, 'OnEditInExcelWithSearch', '', false, false)]
    local procedure EditInExcelWithSearchFilter(ServiceName: Text[240]; ODataFilter: Text; SearchFilter: Text)
    begin
        if StrPos(ODataFilter, '$filter=') = 0 then
            ODataFilter := StrSubstNo('%1%2', '$filter=', ODataFilter);

        GetEndPointAndCreateWorkbook(ServiceName, ODataFilter, SearchFilter);
    end;

    [Scope('OnPrem')]
    procedure ExternalizeODataObjectName(Name: Text) ConvertedName: Text
    var
        CurrentPosition: Integer;
    begin
        ConvertedName := Name;

        // Mimics the behavior of the compiler when converting a field or web service name to OData.
        CurrentPosition := StrPos(ConvertedName, '%');
        while CurrentPosition > 0 do begin
            ConvertedName := DelStr(ConvertedName, CurrentPosition, 1);
            ConvertedName := InsStr(ConvertedName, 'Percent', CurrentPosition);
            CurrentPosition := StrPos(ConvertedName, '%');
        end;

        CurrentPosition := 1;

        while CurrentPosition <= StrLen(ConvertedName) do begin
            if ConvertedName[CurrentPosition] in [' ', '\', '/', '''', '"', '.', '(', ')', '-', ':'] then
                if CurrentPosition > 1 then begin
                    if ConvertedName[CurrentPosition - 1] = '_' then begin
                        ConvertedName := DelStr(ConvertedName, CurrentPosition, 1);
                        CurrentPosition -= 1;
                    end else
                        ConvertedName[CurrentPosition] := '_';
                end else
                    ConvertedName[CurrentPosition] := '_';

            CurrentPosition += 1;
        end;

        ConvertedName := RemoveTrailingUnderscore(ConvertedName);
    end;

    local procedure RemoveTrailingUnderscore(Input: Text): Text
    begin
        Input := DelChr(Input, '>', '_');
        exit(Input);
    end;

    local procedure AddBalanceSheetCellValues()
    begin
        WorksheetWriter.Name(BalanceSheetNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', BalanceSheetHeadingTxt);

        WorksheetWriter.SetCellValueText(4, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(8, 'B', AsOfDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(11, 'B', DesciptionTxt);
        WorksheetWriter.UpdateTableColumnHeader('BalanceSheetTable', DescriptionStaticTxt, DesciptionTxt);
        WorksheetWriter.UpdateCellValueText(11, 'C', BalanceTxt);
        WorksheetWriter.UpdateTableColumnHeader('BalanceSheetTable', BalanceStaticTxt, BalanceTxt);
    end;

    local procedure AddSummaryTrialBalancetCellValues()
    begin
        WorksheetWriter.Name(SummaryTrialBalanceNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', SummaryTrialBalanceHeadingTxt);
        WorksheetWriter.SetCellValueText(2, 'F', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'F', FromDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'F', ToDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(7, 'B', NoTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', NoStaticTxt, NoTxt);
        WorksheetWriter.UpdateCellValueText(7, 'C', NameTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', NameStaticTxt, NameTxt);
        WorksheetWriter.UpdateCellValueText(7, 'D', BeginningBalanceTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', BeginningBalanceStaticTxt, BeginningBalanceTxt);
        WorksheetWriter.UpdateCellValueText(7, 'E', TotalDebitActivitiesTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', TotalDebitStaticTxt, TotalDebitActivitiesTxt);
        WorksheetWriter.UpdateCellValueText(7, 'F', TotalCreditActivitiesTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', TotalCreditStaticTxt, TotalCreditActivitiesTxt);
        WorksheetWriter.UpdateCellValueText(7, 'G', EndingBalanceTxt);
        WorksheetWriter.UpdateTableColumnHeader('SummaryTrialBalanceTable', EndingBalanceStaticTxt, EndingBalanceTxt);
    end;

    local procedure AddIncomeStatementCellValues()
    begin
        WorksheetWriter.Name(IncomeStatementNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', IncomeStatementHeadingTxt);

        WorksheetWriter.SetCellValueText(5, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(9, 'B', FromDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', ToDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(12, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(13, 'B', AccountNameTxt);
        WorksheetWriter.UpdateTableColumnHeader('IncomeStatementTable', AccountNameStaticTxt, AccountNameTxt);
        WorksheetWriter.UpdateCellValueText(13, 'C', NetChangeTxt);
        WorksheetWriter.UpdateTableColumnHeader('IncomeStatementTable', NetChangeStaticTxt, NetChangeTxt);
    end;

    local procedure AddStatementOfRetainedEarningsCellValues()
    begin
        WorksheetWriter.Name(StatementOfRetainedEarningsNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', StatementOfRetainedEarningsHeadingTxt);

        WorksheetWriter.SetCellValueText(5, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(9, 'B', StartingDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', EndingDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(12, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(13, 'B', DesciptionTxt);
        WorksheetWriter.UpdateTableColumnHeader('StatementofRetainedEarningsTable', DescriptionStaticTxt, DesciptionTxt);
        WorksheetWriter.UpdateCellValueText(13, 'C', NetChangeTxt);
        WorksheetWriter.UpdateTableColumnHeader('StatementofRetainedEarningsTable', NetChangeStaticTxt, NetChangeTxt);
    end;

    local procedure AddAgedAccountsPayableCellValues()
    begin
        WorksheetWriter.Name(AgedAccountsPayableNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'C', AgedAccountsPayableHeadingTxt);

        WorksheetWriter.SetCellValueText(2, 'G', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'C', AgedAsOfDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'G', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'C', AgedByTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'D', DueDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'G', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'H', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(7, 'C', NoTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', NoStaticTxt, NoTxt);
        WorksheetWriter.UpdateCellValueText(7, 'D', NameTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', NameStaticTxt, NameTxt);
        WorksheetWriter.UpdateCellValueText(7, 'E', BalanceDueTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', BalanceDueStaticTxt, BalanceDueTxt);
        WorksheetWriter.UpdateCellValueText(7, 'F', CurrentTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', CurrentStaticTxt, CurrentTxt);
        WorksheetWriter.UpdateCellValueText(7, 'G', UpTo30DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', UpTo30StaticTxt, UpTo30DaysTxt);
        WorksheetWriter.UpdateCellValueText(7, 'H', Days31To60Txt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', Days31To60StaticTxt, Days31To60Txt);
        WorksheetWriter.UpdateCellValueText(7, 'I', Over60DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsPayableTable', Over60StaticTxt, Over60DaysTxt);
    end;

    local procedure AddAgedAccountsReceivableCellValues()
    begin
        WorksheetWriter.Name(AgedAccountsReceivableNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'C', AgedAccountsReceivableHeaderTxt);

        WorksheetWriter.SetCellValueText(2, 'G', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'C', AgedAsOfDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(4, 'G', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'C', AgedByTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'D', DueDateTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(5, 'G', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'H', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(7, 'C', NoTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', NoStaticTxt, NoTxt);
        WorksheetWriter.UpdateCellValueText(7, 'D', NameTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', NameStaticTxt, NameTxt);
        WorksheetWriter.UpdateCellValueText(7, 'E', BalanceDueTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', BalanceDueStaticTxt, BalanceDueTxt);
        WorksheetWriter.UpdateCellValueText(7, 'F', CurrentTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', CurrentStaticTxt, CurrentTxt);
        WorksheetWriter.UpdateCellValueText(7, 'G', UpTo30DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', UpTo30StaticTxt, UpTo30DaysTxt);
        WorksheetWriter.UpdateCellValueText(7, 'H', Days31To60Txt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', Days31To60StaticTxt, Days31To60Txt);
        WorksheetWriter.UpdateCellValueText(7, 'I', Over60DaysTxt);
        WorksheetWriter.UpdateTableColumnHeader('AgedAccountsReceivableTable', Over60StaticTxt, Over60DaysTxt);
    end;

    local procedure AddCashFlowStatementCellValues()
    begin
        WorksheetWriter.Name(CashFlowNameTxt);

        WorksheetWriter.UpdateCellValueText(2, 'B', CashFlowHeadingTxt);

        WorksheetWriter.SetCellValueText(5, 'B', CompanyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(6, 'B', CurrencyTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(7, 'B', PrintedTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(9, 'B', PeriodStartTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(10, 'B', PeriodEndTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.SetCellValueText(12, 'B', PrintDollarLinesTxt, WorksheetWriter.DefaultCellDecorator);
        WorksheetWriter.UpdateCellValueText(13, 'B', DesciptionTxt);
        WorksheetWriter.UpdateTableColumnHeader('CashFlowTable', DescriptionStaticTxt, DesciptionTxt);
        WorksheetWriter.UpdateCellValueText(13, 'C', NetChangeTxt);
        WorksheetWriter.UpdateTableColumnHeader('CashFlowTable', NetChangeStaticTxt, NetChangeTxt);
    end;

    [Scope('OnPrem')]
    procedure GetTenantWebServiceMetadata(TenantWebService: Record "Tenant Web Service"; var TenantWebServiceMetadata: DotNet QueryMetadataReader)
    var
        AllObj: Record AllObj;
        ApplicationObjectMetadata: Record "Application Object Metadata";
        inStream: InStream;
    begin
        AllObj.Get(TenantWebService."Object Type", TenantWebService."Object ID");
        ApplicationObjectMetadata.Get(AllObj."App Runtime Package ID", TenantWebService."Object Type", TenantWebService."Object ID");
        if not ApplicationObjectMetadata.Metadata.HasValue then
            exit;

        ApplicationObjectMetadata.CalcFields(Metadata);
        ApplicationObjectMetadata.Metadata.CreateInStream(inStream, TEXTENCODING::Windows);

        TenantWebServiceMetadata := TenantWebServiceMetadata.FromStream(inStream);
    end;

    local procedure GetExcelAddinProviderServiceUrl(): Text
    var
        EnvironmentInfo: Codeunit "Environment Information";
        UrlHelper: Codeunit "Url Helper";
    begin
        exit(UrlHelper.GetExcelAddinProviderServiceUrl);
    end;

    procedure GetHostName(): Text
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if EnvironmentInfo.IsSaaS() then
            exit(GetExcelAddinProviderServiceUrl);
        exit(GetUrl(CLIENTTYPE::Web));
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000006, 'OnEditInExcel', '', false, false)]
    local procedure ReRaiseOnEditInExcel(ServiceName: Text[240]; ODataFilter: Text)
    begin
        OnEditInExcel(ServiceName, ODataFilter)
    end;

    [EventSubscriber(ObjectType::Codeunit, 2000000006, 'OnEditInExcelWithSearchString', '', false, false)]
    local procedure ReRaiseOnEditInExcelWithSearchString(ServiceName: Text[240]; ODataFilter: Text; SearchString: Text)
    begin
        OnEditInExcelWithSearch(ServiceName, ODataFilter, SearchString)
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEditInExcel(ServiceName: Text[240]; ODataFilter: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEditInExcelWithSearch(ServiceName: Text[240]; ODataFilter: Text; SearchFilter: Text)
    begin
    end;
}

