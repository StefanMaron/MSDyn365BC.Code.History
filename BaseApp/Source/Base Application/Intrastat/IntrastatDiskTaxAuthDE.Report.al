#if not CLEAN22
report 11014 "Intrastat - Disk Tax Auth DE"
{
    Caption = 'Intrastat - Disk Tax Auth DE';
    ProcessingOnly = true;
    ObsoleteState = Pending;
#pragma warning disable AS0072
    ObsoleteTag = '22.0';
#pragma warning restore AS0072
    ObsoleteReason = 'Intrastat related functionalities are moving to Intrastat extension.';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
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
                    if ShipmentExists or ReceiptExists then
                        IntrastatExportMgtDACH.WriteXMLHeader(
                            XMLDocument, RootXMLNode, TestSubmission, "Intrastat Jnl. Batch".GetStatisticsStartDate());
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

                    IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
                end;

                trigger OnPreDataItem()
                begin
                    if not ReceiptExists then
                        CurrReport.Break();

                    ItemIntrastatJnlLine.Init();
                    DeclarationIntrastatJnlLine.Init();
                    IntrastatExportMgtDACH.WriteXMLDeclaration(
                        RootXMLNode, DeclarationXMLNode, Type::Receipt, "Intrastat Jnl. Batch"."Currency Identifier");
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

                    IntrastatExportMgtDACH.WriteXMLDeclarationTotals(DeclarationXMLNode, DeclarationIntrastatJnlLine);
                end;

                trigger OnPreDataItem()
                begin
                    if not ShipmentExists then
                        CurrReport.Break();

                    ItemIntrastatJnlLine.Init();
                    DeclarationIntrastatJnlLine.Init();
                    IntrastatExportMgtDACH.WriteXMLDeclaration(
                        RootXMLNode, DeclarationXMLNode, Type::Shipment, "Intrastat Jnl. Batch"."Currency Identifier");
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
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        IntrastatFileWriter.Initialize(true, false, 0);
        IntrastatExportMgtDACH.Initialize(CurrentDateTime());
    end;

    trigger OnPostReport()
    begin
        if not ShipmentExists and not ReceiptExists then
            exit;

        IntrastatFileWriter.InitializeNextFile(IntrastatExportMgtDACH.GetXMLFileName());
        XMLDocument.Save(IntrastatFileWriter.GetCurrFileOutStream());
        IntrastatFileWriter.AddCurrFileToResultFile();
        IntrastatFileWriter.CloseAndDownloadResultFile();

        if not TestSubmission then
            SetBatchIsExported("Intrastat Jnl. Batch");
    end;

    var
        ItemIntrastatJnlLine: Record "Intrastat Jnl. Line";
        DeclarationIntrastatJnlLine: Record "Intrastat Jnl. Line";
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
        TestSubmission: Boolean;

    local procedure CheckLine(var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntraJnlManagement.ValidateReportWithAdvancedChecklist(IntrastatJnlLine, Report::"Intrastat - Disk Tax Auth DE", true);
    end;

    [Scope('OnPrem')]
    procedure WriteReceiptFile()
    begin
        IntrastatExportMgtDACH.WriteXMLItem(ItemIntrastatJnlLine, DeclarationXMLNode);
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
            "Partner VAT ID" := SourceIntrastatJnlLine."Partner VAT ID";

            Amount += SourceIntrastatJnlLine.Amount;
            Quantity += SourceIntrastatJnlLine.Quantity;
            "Statistical Value" += SourceIntrastatJnlLine."Statistical Value";
            "Total Weight" += SourceIntrastatJnlLine."Total Weight";
        end;
    end;

    procedure InitializeRequest(var newResultFileOutStream: OutStream)
    begin
        IntrastatFileWriter.SetResultFileOutStream(newResultFileOutStream);
    end;
}
#endif