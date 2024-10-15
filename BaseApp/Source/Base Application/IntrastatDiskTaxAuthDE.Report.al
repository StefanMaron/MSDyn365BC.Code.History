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
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", Area, "Transaction Specification", "Country/Region of Origin Code");

                trigger OnAfterGetRecord()
                begin
                    if IsBlankedLine("Intrastat Jnl. Line") then
                        CurrReport.Skip();

                    TestField("Tariff No.");
                    TestField("Country/Region Code");
                    TestField("Transaction Type");
                    if CompanyInfo."Check Transport Method" then
                        TestField("Transport Method");
                    TestField(Area);
                    if CompanyInfo."Check Transaction Specific." then
                        TestField("Transaction Specification");
                    if Type = Type::Receipt then
                        TestField("Country/Region of Origin Code");
                    if "Supplementary Units" then
                        TestField(Quantity);
                    CompoundField :=
                      Format("Country/Region Code", 10) + Format(DelChr("Tariff No."), 10) +
                      Format("Transaction Type", 10) + Format("Transport Method", 10) +
                      Format(Area, 10) + Format("Transaction Specification", 10) + Format("Country/Region of Origin Code", 10);

                    if (TempType <> Type) or (StrLen(TempCompoundField) = 0) then begin
                        TempType := Type;
                        TempCompoundField := CompoundField;
                        IntraReferenceNo := CopyStr(IntraReferenceNo, 1, 4) + '000001';
                    end else
                        if TempCompoundField <> CompoundField then begin
                            TempCompoundField := CompoundField;
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
                    if (FormatType = FormatType::XML) and (ShipmentExists or ReceiptExists) then
                        IntrastatExportMgtDACH.WriteXMLHeader(
                          XMLDocument, RootXMLNode, TestSubmission, "Intrastat Jnl. Batch".GetStatisticsStartDate());
                end;

                trigger OnPreDataItem()
                begin
                    "Intrastat Jnl. Line".Reset();
                    "Intrastat Jnl. Line".SetCurrentKey("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.",
                      "Transaction Type", "Transport Method", Area, "Transaction Specification",
                      "Country/Region of Origin Code");
                    "Intrastat Jnl. Line".CopyFilters(IntrastatJnlLine4);
                end;
            }
            dataitem(IntrastatJnlLine2; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.") WHERE(Type = CONST(Receipt));

                trigger OnAfterGetRecord()
                begin
                    if IsBlankedLine(IntrastatJnlLine2) then
                        CurrReport.Skip();

                    if (ItemIntrastatJnlLine."Internal Ref. No." <> '') and
                       (ItemIntrastatJnlLine."Internal Ref. No." <> "Internal Ref. No.")
                    then begin
                        WriteReceiptFile();
                        ItemIntrastatJnlLine.Init();
                    end;

                    AddIntrastatJnlLine(ItemIntrastatJnlLine, IntrastatJnlLine2);
                    AddIntrastatJnlLine(DeclarationIntrastatJnlLine, IntrastatJnlLine2);
                end;

                trigger OnPostDataItem()
                begin
                    if not ReceiptExists then
                        CurrReport.Break();

                    if ItemIntrastatJnlLine."Internal Ref. No." <> '' then
                        WriteReceiptFile();

                    case FormatType of
                        FormatType::ASCII:
                            IntrastatExportMgtDACH.SaveAndCloseFile(ASCIIFileBodyText, XMLDocument, ServerFileReceipts, FormatType);
                        FormatType::XML:
                            IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not ReceiptExists then
                        CurrReport.Break();

                    ItemIntrastatJnlLine.Init();
                    DeclarationIntrastatJnlLine.Init();
                    ASCIIFileBodyText := '';
                    if FormatType = FormatType::XML then
                        IntrastatExportMgtDACH.WriteXMLDeclaration(
                          RootXMLNode, DeclarationXMLNode, Type::Receipt, "Intrastat Jnl. Batch"."Currency Identifier");
                end;
            }
            dataitem(IntrastatJnlLine5; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", Type, "Internal Ref. No.") WHERE(Type = CONST(Shipment));

                trigger OnAfterGetRecord()
                begin
                    if IsBlankedLine(IntrastatJnlLine5) then
                        CurrReport.Skip();

                    if (ItemIntrastatJnlLine."Internal Ref. No." <> '') and
                       (ItemIntrastatJnlLine."Internal Ref. No." <> "Internal Ref. No.")
                    then begin
                        WriteShipmentFile();
                        ItemIntrastatJnlLine.Init();
                    end;

                    AddIntrastatJnlLine(ItemIntrastatJnlLine, IntrastatJnlLine5);
                    AddIntrastatJnlLine(DeclarationIntrastatJnlLine, IntrastatJnlLine5);
                end;

                trigger OnPostDataItem()
                begin
                    if not ShipmentExists then
                        CurrReport.Break();

                    if ItemIntrastatJnlLine."Internal Ref. No." <> '' then
                        WriteShipmentFile();

                    case FormatType of
                        FormatType::ASCII:
                            IntrastatExportMgtDACH.SaveAndCloseFile(ASCIIFileBodyText, XMLDocument, ServerFileShipments, FormatType);
                        FormatType::XML:
                            IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not ShipmentExists then
                        CurrReport.Break();

                    ItemIntrastatJnlLine.Init();
                    DeclarationIntrastatJnlLine.Init();
                    ASCIIFileBodyText := '';
                    if FormatType = FormatType::XML then
                        IntrastatExportMgtDACH.WriteXMLDeclaration(
                          RootXMLNode, DeclarationXMLNode, Type::Shipment, "Intrastat Jnl. Batch"."Currency Identifier");
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField(Reported, false);
                TestField("Currency Identifier");
                IntraReferenceNo := "Statistics Period" + '000000';
            end;

            trigger OnPreDataItem()
            begin
                IntrastatJnlLine4.CopyFilter("Journal Template Name", "Journal Template Name");
                IntrastatJnlLine4.CopyFilter("Journal Batch Name", Name);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field("Format Type"; FormatType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Export Format Type';
                        OptionCaption = 'ASCII,XML';
                        ToolTip = 'Specifies the export file format type.';
                    }
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
        var
            IntrastatSetup: Record "Intrastat Setup";
        begin
            if not IntrastatSetup.Get then
                exit;

            if IntrastatSetup."Report Receipts" and IntrastatSetup."Report Shipments" then
                exit;

            if IntrastatSetup."Report Receipts" then
                "Intrastat Jnl. Line".SetRange(Type, "Intrastat Jnl. Line".Type::Receipt)
            else
                if IntrastatSetup."Report Shipments" then
                    "Intrastat Jnl. Line".SetRange(Type, "Intrastat Jnl. Line".Type::Shipment)
                else
                    Error(NoValuesErr);
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if not ShipmentExists and not ReceiptExists then
            exit;

        if FormatType = FormatType::XML then
            IntrastatExportMgtDACH.SaveAndCloseFile(ASCIIFileBodyText, XMLDocument, ServerFileShipments, FormatType);

        IntrastatExportMgtDACH.DownloadFile(
          ZipArchiveName, ServerFileReceipts, ServerFileShipments, FormatType, "Intrastat Jnl. Batch"."Statistics Period");

        if not TestSubmission then begin
            "Intrastat Jnl. Batch".Reported := true;
            "Intrastat Jnl. Batch".Modify();
        end;
    end;

    trigger OnPreReport()
    begin
        IntrastatJnlLine4.CopyFilters("Intrastat Jnl. Line");
        IntrastatExportMgtDACH.Initialize(CurrentDateTime());
        CompanyInfo.Get();
    end;

    var
        IntrastatJnlLine4: Record "Intrastat Jnl. Line";
        ItemIntrastatJnlLine: Record "Intrastat Jnl. Line";
        DeclarationIntrastatJnlLine: Record "Intrastat Jnl. Line";
        CompanyInfo: Record "Company Information";
        IntrastatExportMgtDACH: Codeunit "Intrastat - Export Mgt. DACH";
        XMLDocument: DotNet XmlDocument;
        RootXMLNode: DotNet XmlNode;
        DeclarationXMLNode: DotNet XmlNode;
        CompoundField: Text[70];
        TempCompoundField: Text[70];
        IntraReferenceNo: Text[10];
        ASCIIFileBodyText: Text;
        ServerFileShipments: Text;
        ServerFileReceipts: Text;
        ZipArchiveName: Text;
        TempType: Integer;
        FormatType: Option ASCII,XML;
        ShipmentExists: Boolean;
        ReceiptExists: Boolean;
        TestSubmission: Boolean;
        NoValuesErr: Label 'You must select the Report Receipts and Report Shipments check boxes on the Intrastat Setup page.';

    [Scope('OnPrem')]
    procedure WriteReceiptFile()
    begin
        if FormatType = FormatType::ASCII then
            IntrastatExportMgtDACH.WriteASCII(
              ASCIIFileBodyText, ItemIntrastatJnlLine, "Intrastat Jnl. Batch"."Currency Identifier", '11', '', ' ', '  ', '')
        else
            IntrastatExportMgtDACH.WriteXMLItem(ItemIntrastatJnlLine, DeclarationXMLNode);
    end;

    [Scope('OnPrem')]
    procedure WriteShipmentFile()
    begin
        if FormatType = FormatType::ASCII then
            IntrastatExportMgtDACH.WriteASCII(
              ASCIIFileBodyText, ItemIntrastatJnlLine, "Intrastat Jnl. Batch"."Currency Identifier", '22', ' ', '', '', '  ')
        else
            IntrastatExportMgtDACH.WriteXMLItem(ItemIntrastatJnlLine, DeclarationXMLNode);
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

            Amount += SourceIntrastatJnlLine.Amount;
            Quantity += SourceIntrastatJnlLine.Quantity;
            "Statistical Value" += SourceIntrastatJnlLine."Statistical Value";
            "Total Weight" += SourceIntrastatJnlLine."Total Weight";
        end;
    end;

    local procedure IsBlankedLine(IntrastatJnlLine: Record "Intrastat Jnl. Line"): Boolean
    begin
        with IntrastatJnlLine do
            exit(
              ("Tariff No." = '') and
              ("Country/Region Code" = '') and
              ("Transaction Type" = '') and
              ("Transport Method" = '') and
              (Area = '') and
              ("Transaction Specification" = '') and
              ("Total Weight" = 0));
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewZipArchiveName: Text)
    begin
        ZipArchiveName := NewZipArchiveName;
    end;
}

