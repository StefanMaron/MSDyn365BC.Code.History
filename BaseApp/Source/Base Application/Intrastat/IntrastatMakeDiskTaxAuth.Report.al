report 593 "Intrastat - Make Disk Tax Auth"
{
    Caption = 'Intrastat - Make Disk Tax Auth';
    ProcessingOnly = true;

    dataset
    {
        dataitem(IntrastatJnlBatch; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            dataitem(IntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Transaction Specification", Area);
                RequestFilterFields = Type;

                trigger OnAfterGetRecord()
                begin
                    ValidateIntrastatJournalLine;
                    UpdateBuffer;
                end;

                trigger OnPostDataItem()
                var
                    ExportType: Option Receipt,Shipment;
                begin
#if CLEAN19
                    IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);
#else
                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.CheckForJournalBatchError(IntrastatJnlLine, true);
#endif
                    TempIntrastatJnlLine.Reset();

                    // Reciepts
                    if StrPos(GetFilter(Type), Format(Type::Receipt)) <> 0 then begin
                        CreateReportNode(ExportType::Receipt);
                        IntrastatJnlBatch."System 19 reported" := true;
                    end;

                    // Shipments
                    if StrPos(GetFilter(Type), Format(Type::Shipment)) <> 0 then begin
                        CreateReportNode(ExportType::Shipment);
                        IntrastatJnlBatch."System 29 reported" := true;
                    end;

                    IntrastatJnlBatch.Modify();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField("Statistics Period");
                if StrPos(IntrastatJnlLine.GetFilter(Type), Format(IntrastatJnlLine.Type::Receipt)) <> 0 then
                    TestField("System 19 reported", false);

                if StrPos(IntrastatJnlLine.GetFilter(Type), Format(IntrastatJnlLine.Type::Shipment)) <> 0 then
                    TestField("System 29 reported", false);

                ReportingDate := ConvertPeriodToDate("Statistics Period");

                TempIntrastatJnlLine.DeleteAll();
                IntraJnlManagement.ChecklistClearBatchErrors(IntrastatJnlBatch);
                IntrastatFileWriter.Initialize(false, false, 0);
                IntrastatFileWriter.SetStatisticsPeriod("Statistics Period");
                IntrastatFileWriter.InitializeNextFile(IntrastatFileWriter.GetDefaultXMLFileName());
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(Nihil; Nihil)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Nihil declaration';
                        ToolTip = 'Specifies if you do not have any trade transactions with European Union (EU) countries/regions and want to send an empty declaration.';
                    }
                    field(Counterparty; CounterpartyInfo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Counter party info';
                        ToolTip = 'Specifies if counter party information and country of origin will be included.';
                    }
                    group("Third party :")
                    {
                        Caption = 'Third party :';
                        field(ThirdPartyVatRegNo; ThirdPartyVatRegNo)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Enterprise No./VAT Reg. No.';
                            ToolTip = 'Specifies the enterprise or VAT registration number.';
                        }
                    }
                    field(Dir; Dir)
                    {
                        ApplicationArea = Advanced;
                        Caption = 'Directory';
                        ToolTip = 'Specifies the directory which the file will be saved to.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            FilterSourceLinesByIntrastatSetupExportTypes();
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
    end;

    trigger OnPostReport()
    var
        FileOutStream: OutStream;
    begin
        IntrastatFileWriter.GetCurrFileOutStream(FileOutStream);
        XMLDoc.Save(FileOutStream);
        IntrastatFileWriter.AddCurrFileToResultFile();
        IntrastatFileWriter.CloseAndDownloadResultFile();
    end;

    trigger OnPreReport()
    var
        CompanyInformation: Record "Company Information";
        VATLogicalTests: Codeunit VATLogicalTests;
    begin
        if IntrastatJnlLine.GetFilter(Type) = '' then
            IntrastatJnlLine.FieldError(Type, ReceiptShipmentErr);

        if ThirdPartyVatRegNo <> '' then
            EnterpriseNo := DelChr(ThirdPartyVatRegNo, '=', DelChr(ThirdPartyVatRegNo, '=', '0123456789'))
        else begin
            CompanyInformation.Get();
            if not VATLogicalTests.MOD97Check(CompanyInformation."Enterprise No.") then
                Error(EnterpriseNoNotValidErr);
            EnterpriseNo := DelChr(CompanyInformation."Enterprise No.", '=', DelChr(CompanyInformation."Enterprise No.", '=', '0123456789'));
        end;

        CreateXMLDocument;
    end;

    var
        ReceiptShipmentErr: Label 'must be Receipt or Shipment';
        GreaterThanZeroErr: Label 'must be more than 0';
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line" temporary;
        GLSetup: Record "General Ledger Setup";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        XMLDOMManagement: Codeunit "XML DOM Management";
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        XMLDoc: DotNet XmlDocument;
        RootNode: DotNet XmlNode;
        Node: DotNet XmlNode;
        AdministrationNode: DotNet XmlNode;
        Namespace: Text;
        ThirdPartyVatRegNo: Text[30];
        EnterpriseNo: Text[30];
        ReportingDate: Date;
        Nihil: Boolean;
        CounterpartyInfo: Boolean;
        NextLine: Integer;
        Dir: Text;
        EnterpriseNoNotValidErr: Label 'The enterprise number in Company Information is not valid.';
        StandardReportTxt: Label 'INTRASTAT_X_S', Locked = true;
        StandardFormTxt: Label 'INTRASTAT_X_SF', Locked = true;
        ExtendedReportTxt: Label 'INTRASTAT_X_E', Locked = true;
        ExtendedFormTxt: Label 'INTRASTAT_X_EF', Locked = true;
        IntrastatReportName: Text;
        IntrastatFormName: Text;

    local procedure FilterSourceLinesByIntrastatSetupExportTypes()
    begin
        if not IntrastatSetup.Get() then
            exit;

        if IntrastatJnlLine.GetFilter(Type) <> '' then
            exit;

        if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
            exit;

        if IntrastatSetup."Report Receipts" then
            IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Receipt)
        else
            if IntrastatSetup."Report Shipments" then
                IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment)
    end;

    local procedure UpdateBuffer()
    begin
        with IntrastatJnlLine do begin
            TempIntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
            TempIntrastatJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
            TempIntrastatJnlLine.SetRange(Type, Type);
            TempIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
            TempIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
            TempIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
            TempIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
            TempIntrastatJnlLine.SetRange("Transaction Specification", "Transaction Specification");
            TempIntrastatJnlLine.SetRange(Area, Area);
            if CounterpartyInfo and (Type = Type::Shipment) then begin
                TempIntrastatJnlLine.SetRange("Country/Region of Origin Code", "Country/Region of Origin Code");
                TempIntrastatJnlLine.SetRange("Partner VAT ID", "Partner VAT ID");
            end;
            if TempIntrastatJnlLine.FindFirst() then begin
                TempIntrastatJnlLine."Statistical Value" := TempIntrastatJnlLine."Statistical Value" + "Statistical Value";
                TempIntrastatJnlLine."Total Weight" := TempIntrastatJnlLine."Total Weight" + "Total Weight";
                TempIntrastatJnlLine."No. of Supplementary Units" :=
                  TempIntrastatJnlLine."No. of Supplementary Units" + "No. of Supplementary Units";
                TempIntrastatJnlLine."Document No." := "Document No.";
                TempIntrastatJnlLine.Modify();
            end else begin
                TempIntrastatJnlLine.Init();
                TempIntrastatJnlLine."Journal Template Name" := "Journal Template Name";
                TempIntrastatJnlLine."Journal Batch Name" := "Journal Batch Name";
                TempIntrastatJnlLine.Type := Type;
                TempIntrastatJnlLine."Country/Region Code" := "Country/Region Code";
                TempIntrastatJnlLine."Tariff No." := "Tariff No.";
                TempIntrastatJnlLine."Transaction Type" := "Transaction Type";
                TempIntrastatJnlLine."Transport Method" := "Transport Method";
                TempIntrastatJnlLine."Transaction Specification" := "Transaction Specification";
                TempIntrastatJnlLine.Area := Area;
                NextLine := NextLine + 10000;
                TempIntrastatJnlLine."Line No." := NextLine;
                TempIntrastatJnlLine."Statistical Value" := "Statistical Value";
                TempIntrastatJnlLine."Total Weight" := "Total Weight";
                TempIntrastatJnlLine."No. of Supplementary Units" := "No. of Supplementary Units";
                TempIntrastatJnlLine."Document No." := "Document No.";
                TempIntrastatJnlLine."Country/Region of Origin Code" := "Country/Region of Origin Code";
                TempIntrastatJnlLine."Partner VAT ID" := "Partner VAT ID";
                TempIntrastatJnlLine.Insert();
            end;
        end;
    end;

    local procedure CreateXMLDocument()
    begin
        // Create XML Document
        XMLDoc := XMLDoc.XmlDocument;
        Namespace := 'http://www.onegate.eu/2010-01-01';

        // Header
        XMLDOMManagement.AddRootElementWithPrefix(XMLDoc, 'DeclarationReport', '', Namespace, RootNode);
        XMLDOMManagement.AddDeclaration(XMLDoc, '1.0', 'UTF-8', '');

        // Adminitration
        XMLDOMManagement.AddElement(RootNode, 'Administration', '', Namespace, AdministrationNode);
        XMLDOMManagement.AddElement(AdministrationNode, 'From', EnterpriseNo, Namespace, Node);
        XMLDOMManagement.AddAttribute(Node, 'declarerType', 'KBO');
        XMLDOMManagement.AddElement(AdministrationNode, 'To', 'NBB', Namespace, Node);
        XMLDOMManagement.AddElement(AdministrationNode, 'Domain', 'SXX', Namespace, Node);
    end;

    local procedure CreateReportNode(ExportType: Option Receipt,Shipment)
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CountryRegion: Record "Country/Region";
        Node: DotNet XmlNode;
        ItemNode: DotNet XmlNode;
        DimNode: DotNet XmlNode;
        StatisticalValue: Decimal;
        ReportIsNihil: Boolean;
    begin
        if ExportType = ExportType::Receipt then
            TempIntrastatJnlLine.SetRange(Type, TempIntrastatJnlLine.Type::Receipt)
        else
            TempIntrastatJnlLine.SetRange(Type, TempIntrastatJnlLine.Type::Shipment);

        if Nihil then
            ReportIsNihil := true
        else begin
            if TempIntrastatJnlLine.IsEmpty() then
                ReportIsNihil := true;
        end;

        XMLDOMManagement.AddElement(RootNode, 'Report', '', Namespace, Node);
        if ReportIsNihil then
            XMLDOMManagement.AddAttribute(Node, 'action', 'nihil')
        else
            XMLDOMManagement.AddAttribute(Node, 'action', 'replace');
        XMLDOMManagement.AddAttribute(Node, 'date', Format(ReportingDate, 0, '<Year4>-<Month,2>'));

        PrepareReportNames(ExportType);
        // Report
        XMLDOMManagement.AddAttribute(Node, 'code', IntrastatReportName);
        // Data
        XMLDOMManagement.AddElement(Node, 'Data', '', Namespace, Node);
        XMLDOMManagement.AddAttribute(Node, 'close', 'true');
        XMLDOMManagement.AddAttribute(Node, 'form', IntrastatFormName);

        if ReportIsNihil then
            exit;

        // Item & Dim
        with TempIntrastatJnlLine do begin
            if FindSet() then
                repeat
                    CountryRegion.Get("Country/Region Code");
                    CountryRegion.TestField("Intrastat Code");
                    XMLDOMManagement.AddElement(Node, 'Item', '', Namespace, ItemNode);

                    case Type of
                        Type::Receipt:
                            XMLDOMManagement.AddElement(ItemNode, 'Dim', '19', Namespace, DimNode);
                        Type::Shipment:
                            XMLDOMManagement.AddElement(ItemNode, 'Dim', '29', Namespace, DimNode);
                    end;
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXTRF');
                    XMLDOMManagement.AddElement(ItemNode, 'Dim', CountryRegion."Intrastat Code", Namespace, DimNode);
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXCNT');
                    XMLDOMManagement.AddElement(ItemNode, 'Dim', "Transaction Type", Namespace, DimNode);
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXTTA');
                    XMLDOMManagement.AddElement(ItemNode, 'Dim', Area, Namespace, DimNode);
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXREG');
                    XMLDOMManagement.AddElement(
                      ItemNode, 'Dim', DelChr("Tariff No.", '=', DelChr("Tariff No.", '=', '0123456789')), Namespace, DimNode);
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXTGO');
                    XMLDOMManagement.AddElement(
                        ItemNode, 'Dim', Format(IntraJnlManagement.RoundTotalWeight("Total Weight"), 0, 9), Namespace, DimNode);
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXWEIGHT');
                    XMLDOMManagement.AddElement(
                      ItemNode, 'Dim', Format(Round("No. of Supplementary Units"), 0, 9), Namespace, DimNode);
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXUNITS');
                    if IntrastatJnlBatch."Amounts in Add. Currency" then begin
                        GLSetup.TestField("Additional Reporting Currency");
                        Currency.Get(GLSetup."Additional Reporting Currency");
                        Currency.TestField("Amount Rounding Precision");
                        StatisticalValue :=
                          Round(
                            CurrExchRate.ExchangeAmtFCYToLCY(
                              Date, GLSetup."Additional Reporting Currency", "Statistical Value",
                              CurrExchRate.ExchangeRate(
                                Date, GLSetup."Additional Reporting Currency")),
                            Currency."Amount Rounding Precision");
                    end else
                        StatisticalValue := "Statistical Value";
                    XMLDOMManagement.AddElement(ItemNode, 'Dim', Format(Round(StatisticalValue, 1), 0, 9), Namespace, DimNode);
                    XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXTXVAL');
                    if CounterpartyInfo and (Type = Type::Shipment) then begin
                        XMLDOMManagement.AddElement(ItemNode, 'Dim', "Country/Region of Origin Code", Namespace, DimNode);
                        XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXCNTORI');
                        XMLDOMManagement.AddElement(ItemNode, 'Dim', "Partner VAT ID", Namespace, DimNode);
                        XMLDOMManagement.AddAttribute(DimNode, 'prop', 'PARTNERID');
                    end;
                    if not GLSetup."Simplified Intrastat Decl." then begin
                        XMLDOMManagement.AddElement(ItemNode, 'Dim', "Transport Method", Namespace, DimNode);
                        XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXTPC');
                        XMLDOMManagement.AddElement(ItemNode, 'Dim', "Transaction Specification", Namespace, DimNode);
                        XMLDOMManagement.AddAttribute(DimNode, 'prop', 'EXDELTRM');
                    end;
                    Delete;
                until Next() = 0;
        end;
    end;

    local procedure ValidateIntrastatJournalLine()
    var
        TariffNumber: Record "Tariff Number";
    begin
#if CLEAN19
        IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Make Disk Tax Auth", false);
#else
        if IntrastatSetup."Use Advanced Checklist" then
            IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Make Disk Tax Auth", false)
        else begin
            IntrastatJnlLine.TestField("Country/Region Code");
            IntrastatJnlLine.TestField("Transaction Type");
            IntrastatJnlLine.TestField(Area);
            IntrastatJnlLine.TestField("Tariff No.");
        end;
#endif
        with IntrastatJnlLine do begin
            if not GLSetup."Simplified Intrastat Decl." then begin
                TestField("Transport Method");
                TestField("Transaction Specification");
            end;

            TariffNumber.Get("Tariff No.");
            if TariffNumber."Weight Mandatory" then begin
                if "Total Weight" <= 0 then
                    FieldError("Total Weight", GreaterThanZeroErr);
            end else
                TestField("Supplementary Units", true);

            if "Statistical Value" <= 0 then
                FieldError("Statistical Value", GreaterThanZeroErr);
        end;
    end;

    local procedure ConvertPeriodToDate(Period: Code[10]): Date
    var
        Month: Integer;
        Year: Integer;
        Century: Integer;
    begin
        Century := Date2DMY(WorkDate, 3) div 100;
        Evaluate(Year, CopyStr(Period, 1, 2));
        Year := Year + Century * 100;
        Evaluate(Month, CopyStr(Period, 3, 2));
        exit(DMY2Date(1, Month, Year));
    end;

#if not CLEAN20
    [Scope('OnPrem')]
    procedure InitializeRequest(NewClientFileName: Text; NewThirdPartyVatRegNo: Text[30]; NewNihil: Boolean; NewCounterparty: Boolean)
    begin
        IntrastatFileWriter.SetServerFileName(NewClientFileName);
        ThirdPartyVatRegNo := NewThirdPartyVatRegNo;
        Nihil := NewNihil;
        CounterpartyInfo := NewCounterparty;
    end;
#endif

    procedure InitializeRequest(var newResultFileOutStream: OutStream; NewThirdPartyVatRegNo: Text[30]; NewNihil: Boolean; NewCounterparty: Boolean)
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
        ThirdPartyVatRegNo := NewThirdPartyVatRegNo;
        Nihil := NewNihil;
        CounterpartyInfo := NewCounterparty;
    end;

    local procedure PrepareReportNames(ExportType: Option Receipt,Shipment)
    begin
        case ExportType of
            ExportType::Receipt:
                if GLSetup."Simplified Intrastat Decl." then begin
                    IntrastatReportName := 'EX19S';
                    IntrastatFormName := 'EXF19S';
                end else begin
                    IntrastatReportName := 'EX19E';
                    IntrastatFormName := 'EXF19E';
                end;
            ExportType::Shipment:
                if CounterpartyInfo then
                    if GLSetup."Simplified Intrastat Decl." then begin
                        IntrastatReportName := StandardReportTxt;
                        IntrastatFormName := StandardFormTxt;
                    end else begin
                        IntrastatReportName := ExtendedReportTxt;
                        IntrastatFormName := ExtendedFormTxt;
                    end
                else
                    if GLSetup."Simplified Intrastat Decl." then begin
                        IntrastatReportName := 'EX29S';
                        IntrastatFormName := 'EXF29S';
                    end else begin
                        IntrastatReportName := 'EX29E';
                        IntrastatFormName := 'EXF29E';
                    end;
        end;
    end;
}

