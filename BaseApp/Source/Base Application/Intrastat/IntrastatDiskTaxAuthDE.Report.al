report 11014 "Intrastat - Disk Tax Auth DE"
{
    Caption = 'Intrastat - Disk Tax Auth DE';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            dataitem(IntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", Area, "Transaction Specification", "Country/Region of Origin Code", "Partner VAT ID");

                trigger OnAfterGetRecord()
                begin
                    if IsBlankedLine(IntrastatJnlLine) then
                        CurrReport.Skip();

                    CheckLine(IntrastatJnlLine);

                    CompoundField := GetCompound(IntrastatJnlLine);
                    if (PrevType <> Type) or (StrLen(PrevCompoundField) = 0) then begin
                        PrevType := Type;
                        PrevCompoundField := CompoundField;
                        IntraReferenceNo := CopyStr(IntraReferenceNo, 1, 4) + '000001';
                    end else
                        if PrevCompoundField <> CompoundField then begin
                            PrevCompoundField := CompoundField;
                            if CopyStr(IntraReferenceNo, 8, 3) = '999' then
                                IntraReferenceNo := IncStr(CopyStr(IntraReferenceNo, 1, 7)) + '001'
                            else
                                IntraReferenceNo := IncStr(IntraReferenceNo);
                        end;

                    "Internal Ref. No." := IntraReferenceNo;
                    Modify();

                    case Type of
                        Type::Receipt:
                            ReceiptExists := true;
                        Type::Shipment:
                            ShipmentExists := true;
                    end;
                end;

                trigger OnPostDataItem()
                begin
#if not CLEAN20
                    if (FormatType = FormatType::XML) and (ShipmentExists or ReceiptExists) then
                        IntrastatExportMgtDACH.WriteXMLHeader(
                          XMLDocument, RootXMLNode, TestSubmission, "Intrastat Jnl. Batch".GetStatisticsStartDate());
#else
                    if ShipmentExists or ReceiptExists then
                        IntrastatExportMgtDACH.WriteXMLHeader(
                            XMLDocument, RootXMLNode, TestSubmission, "Intrastat Jnl. Batch".GetStatisticsStartDate());
#endif
                end;
            }
            dataitem(ReceiptIntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.") where(Type = const(Receipt));

                trigger OnAfterGetRecord()
                begin
                    if IsBlankedLine(ReceiptIntrastatJnlLine) then
                        CurrReport.Skip();

                    if (ItemIntrastatJnlLine."Internal Ref. No." <> '') and
                       (ItemIntrastatJnlLine."Internal Ref. No." <> "Internal Ref. No.")
                    then begin
                        WriteReceiptFile();
                        ItemIntrastatJnlLine.Init();
                    end;

                    AddIntrastatJnlLine(ItemIntrastatJnlLine, ReceiptIntrastatJnlLine);
                    AddIntrastatJnlLine(DeclarationIntrastatJnlLine, ReceiptIntrastatJnlLine);
                end;

                trigger OnPostDataItem()
                begin
                    if not ReceiptExists then
                        CurrReport.Break();

                    if ItemIntrastatJnlLine."Internal Ref. No." <> '' then
                        WriteReceiptFile();

#if not CLEAN20
                    case FormatType of
                        FormatType::ASCII:
                            IntrastatExportMgtDACH.SaveAndCloseFile(ASCIIFileBodyText, XMLDocument, ServerFileReceipts, FormatType);
                        FormatType::XML:
                            IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
                    end;
#else
                    IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
#endif
                end;

                trigger OnPreDataItem()
                begin
                    if not ReceiptExists then
                        CurrReport.Break();

                    ItemIntrastatJnlLine.Init();
                    DeclarationIntrastatJnlLine.Init();
#if not CLEAN20
                    ASCIIFileBodyText := '';
                    if FormatType = FormatType::XML then
                        IntrastatExportMgtDACH.WriteXMLDeclaration(
                          RootXMLNode, DeclarationXMLNode, Type::Receipt, "Intrastat Jnl. Batch"."Currency Identifier");
#else
                    IntrastatExportMgtDACH.WriteXMLDeclaration(
                        RootXMLNode, DeclarationXMLNode, Type::Receipt, "Intrastat Jnl. Batch"."Currency Identifier");
#endif
                end;
            }
            dataitem(ShipmentIntrastatJnlLine; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.") where(Type = const(Shipment));

                trigger OnAfterGetRecord()
                begin
                    if IsBlankedLine(ShipmentIntrastatJnlLine) then
                        CurrReport.Skip();

                    if (ItemIntrastatJnlLine."Internal Ref. No." <> '') and
                       (ItemIntrastatJnlLine."Internal Ref. No." <> "Internal Ref. No.")
                    then begin
                        WriteShipmentFile();
                        ItemIntrastatJnlLine.Init();
                    end;

                    AddIntrastatJnlLine(ItemIntrastatJnlLine, ShipmentIntrastatJnlLine);
                    AddIntrastatJnlLine(DeclarationIntrastatJnlLine, ShipmentIntrastatJnlLine);
                end;

                trigger OnPostDataItem()
                begin
                    if not ShipmentExists then
                        CurrReport.Break();

                    if ItemIntrastatJnlLine."Internal Ref. No." <> '' then
                        WriteShipmentFile();

#if not CLEAN20
                    case FormatType of
                        FormatType::ASCII:
                            IntrastatExportMgtDACH.SaveAndCloseFile(ASCIIFileBodyText, XMLDocument, ServerFileShipments, FormatType);
                        FormatType::XML:
                            IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
                    end;
#else
                    IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
#endif
                end;

                trigger OnPreDataItem()
                begin
                    if not ShipmentExists then
                        CurrReport.Break();

                    ItemIntrastatJnlLine.Init();
                    DeclarationIntrastatJnlLine.Init();
#if not CLEAN20
                    ASCIIFileBodyText := '';
                    if FormatType = FormatType::XML then
                        IntrastatExportMgtDACH.WriteXMLDeclaration(
                          RootXMLNode, DeclarationXMLNode, Type::Shipment, "Intrastat Jnl. Batch"."Currency Identifier");
#else
                    IntrastatExportMgtDACH.WriteXMLDeclaration(
                        RootXMLNode, DeclarationXMLNode, Type::Shipment, "Intrastat Jnl. Batch"."Currency Identifier");
#endif
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Reported, false);
                TestField("Currency Identifier");
                IntraReferenceNo := "Statistics Period" + '000000';
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Journal Template Name", IntrastatJnlLine.GetFilter("Journal Template Name"));
                SetFilter(Name, IntrastatJnlLine.GetFilter("Journal Batch Name"));
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
#if not CLEAN20
                    field("Format Type"; FormatType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Format Type';
                        OptionCaption = 'ASCII,XML';
                        ToolTip = 'Specifies the export file format type.';
                        Visible = false;
                        ObsoleteState = Pending;
                        ObsoleteReason = 'Remove legacy ASCII functionality';
                        ObsoleteTag = '20.0';
                    }
#endif
                    field("Test Submission"; TestSubmission)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Submission';
                        ToolTip = 'Specifies if the exported XML will be used for test submission.';
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

    trigger OnPreReport()
    begin
        IntrastatFileWriter.Initialize(true, false, 0);
        IntrastatExportMgtDACH.Initialize(CurrentDateTime());
#if not CLEAN19
        CompanyInfo.Get();
        if IntrastatSetup.Get() then;
#endif

#if not CLEAN20
        FormatType := FormatType::XML;
#endif
    end;

    trigger OnPostReport()
    begin
        if not ShipmentExists and not ReceiptExists then
            exit;

#if not CLEAN20
        if (ZipArchiveName <> '') then begin
            IntrastatExportMgtDACH.SaveAndCloseFile(ASCIIFileBodyText, XMLDocument, ServerFileShipments, FormatType);
            IntrastatExportMgtDACH.DownloadFile(
                ZipArchiveName, ServerFileReceipts, ServerFileShipments, FormatType, "Intrastat Jnl. Batch"."Statistics Period");
        end else begin
            IntrastatFileWriter.InitializeNextFile(IntrastatExportMgtDACH.GetXMLFileName());
            XMLDocument.Save(IntrastatFileWriter.GetCurrFileOutStream());
            IntrastatFileWriter.AddCurrFileToResultFile();
            IntrastatFileWriter.CloseAndDownloadResultFile();
        end;
#else
        IntrastatFileWriter.InitializeNextFile(IntrastatExportMgtDACH.GetXMLFileName());
        XMLDocument.Save(IntrastatFileWriter.GetCurrFileOutStream());
        IntrastatFileWriter.AddCurrFileToResultFile();
        IntrastatFileWriter.CloseAndDownloadResultFile();
#endif

        if not TestSubmission then
            SetBatchIsExported("Intrastat Jnl. Batch");
    end;

    var
        ItemIntrastatJnlLine: Record "Intrastat Jnl. Line";
        DeclarationIntrastatJnlLine: Record "Intrastat Jnl. Line";
#if not CLEAN19
        CompanyInfo: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
#endif
        IntraJnlManagement: Codeunit IntraJnlManagement;
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        IntrastatFileWriter: Codeunit "Intrastat File Writer";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        DeclarationXMLNode: DotNet XmlNode;
        CompoundField: Text;
        PrevCompoundField: Text;
        IntraReferenceNo: Text[10];
        PrevType: Integer;
        ReceiptExists: Boolean;
        ShipmentExists: Boolean;
#if not CLEAN20
        FormatType: Option ASCII,XML;
        ServerFileShipments: Text;
        ZipArchiveName: Text;
        ASCIIFileBodyText: Text;
        ServerFileReceipts: Text;
#endif
        TestSubmission: Boolean;

    local procedure FilterSourceLinesByIntrastatSetupExportTypes()
#if CLEAN19
    var
        IntrastatSetup: Record "Intrastat Setup";
#endif
    begin
        if not IntrastatSetup.Get() then
            exit;

        if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
            exit;

        if IntrastatSetup."Report Receipts" then
            IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Receipt)
        else
            if IntrastatSetup."Report Shipments" then
                IntrastatJnlLine.SetRange(Type, IntrastatJnlLine.Type::Shipment)
    end;

    local procedure CheckLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
#if CLEAN19
        IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Disk Tax Auth DE", true);
#else
        if IntrastatSetup."Use Advanced Checklist" then
            IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Disk Tax Auth DE", true)
        else begin
            IntrastatJnlLine.TestField("Tariff No.");
            IntrastatJnlLine.TestField("Country/Region Code");
            IntrastatJnlLine.TestField("Transaction Type");
            if CompanyInfo."Check Transport Method" then
                IntrastatJnlLine.TestField("Transport Method");
            IntrastatJnlLine.TestField(Area);
            if CompanyInfo."Check Transaction Specific." then
                IntrastatJnlLine.TestField("Transaction Specification");
            if IntrastatJnlLine.Type = IntrastatJnlLine.Type::Receipt then
                IntrastatJnlLine.TestField("Country/Region of Origin Code")
            else begin
                if CompanyInfo."Check for Partner VAT ID" then
                    IntrastatJnlLine.TestField("Partner VAT ID");
                if CompanyInfo."Check for Country of Origin" then
                    IntrastatJnlLine.TestField("Country/Region of Origin Code");
            end;
            if IntrastatJnlLine."Supplementary Units" then
                IntrastatJnlLine.TestField(Quantity);
        end;
#endif
    end;

    [Scope('OnPrem')]
    procedure WriteReceiptFile()
    begin
#if not CLEAN20
        if FormatType = FormatType::ASCII then
            IntrastatExportMgtDACH.WriteASCII(
              ASCIIFileBodyText, ItemIntrastatJnlLine, "Intrastat Jnl. Batch"."Currency Identifier", '11', '', ' ', '  ', '')
        else
            IntrastatExportMgtDACH.WriteXMLItem(ItemIntrastatJnlLine, DeclarationXMLNode);
#else
        IntrastatExportMgtDACH.WriteXMLItem(ItemIntrastatJnlLine, DeclarationXMLNode);
#endif
    end;

    local procedure IsBlankedLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Boolean
    begin
        exit(
            (IntrastatJnlLine."Tariff No." = '') and
            (IntrastatJnlLine."Country/Region Code" = '') and
            (IntrastatJnlLine."Transaction Type" = '') and
            (IntrastatJnlLine."Transport Method" = '') and
            (IntrastatJnlLine.Area = '') and
            (IntrastatJnlLine."Transaction Specification" = '') and
            (IntrastatJnlLine."Total Weight" = 0));
    end;

    local procedure GetCompound(var IntrastatJnlLine: Record "Intrastat Jnl. Line"): Text
    begin
        exit(
            Format(IntrastatJnlLine."Country/Region Code", 10) + Format(DelChr(IntrastatJnlLine."Tariff No."), 20) +
            Format(IntrastatJnlLine."Transaction Type", 10) + Format(IntrastatJnlLine."Transport Method", 10) +
            Format(IntrastatJnlLine.Area, 10) + Format(IntrastatJnlLine."Transaction Specification", 10) +
            Format(IntrastatJnlLine."Partner VAT ID", 50) + Format(IntrastatJnlLine."Country/Region of Origin Code", 10));
    end;


    local procedure SetBatchIsExported(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    begin
        IntrastatJnlBatch.Validate(Reported, true);
        IntrastatJnlBatch.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure WriteShipmentFile()
    begin
#if not CLEAN20
        if FormatType = FormatType::ASCII then
            IntrastatExportMgtDACH.WriteASCII(
              ASCIIFileBodyText, ItemIntrastatJnlLine, "Intrastat Jnl. Batch"."Currency Identifier", '22', ' ', '', '', '  ')
        else
            IntrastatExportMgtDACH.WriteXMLItem(ItemIntrastatJnlLine, DeclarationXMLNode);
#else
        IntrastatExportMgtDACH.WriteXMLItem(ItemIntrastatJnlLine, DeclarationXMLNode);
#endif
    end;

    local procedure AddIntrastatJnlLine(var TargetIntrastatJnlLine: Record "Intrastat Jnl. Line"; SourceIntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        with TargetIntrastatJnlLine do begin
            Type := SourceIntrastatJnlLine.Type;
            "Item Description" := SourceIntrastatJnlLine."Item Description";
            "Internal Ref. No." := SourceIntrastatJnlLine."Internal Ref. No.";
            Date := SourceIntrastatJnlLine.Date;
            "Tariff No." := SourceIntrastatJnlLine."Tariff No.";
            "Country/Region Code" := SourceIntrastatJnlLine."Country/Region Code";
            "Transaction Type" := SourceIntrastatJnlLine."Transaction Type";
            "Transport Method" := SourceIntrastatJnlLine."Transport Method";
            "Supplementary Units" := SourceIntrastatJnlLine."Supplementary Units";
            "Country/Region of Origin Code" := SourceIntrastatJnlLine."Country/Region of Origin Code";
            Area := SourceIntrastatJnlLine.Area;
            "Transaction Specification" := SourceIntrastatJnlLine."Transaction Specification";
            "Document No." := SourceIntrastatJnlLine."Document No.";
            "Partner VAT ID" := SourceIntrastatJnlLine."Partner VAT ID";

            Amount += SourceIntrastatJnlLine.Amount;
            Quantity += SourceIntrastatJnlLine.Quantity;
            "Statistical Value" += SourceIntrastatJnlLine."Statistical Value";
            "Total Weight" += SourceIntrastatJnlLine."Total Weight";
        end;
    end;

#if not CLEAN20
    [Obsolete('Replaced by new InitializeRequest(OutStream)', '20.0')]
    [Scope('OnPrem')]
    procedure InitializeRequest(NewZipArchiveName: Text)
    begin
        ZipArchiveName := NewZipArchiveName;
    end;
#endif

    procedure InitializeRequest(var newResultFileOutStream: OutStream)
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
    end;
}

