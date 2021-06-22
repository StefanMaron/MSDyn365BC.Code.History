page 311 "Intrastat Journal"
{
    ApplicationArea = BasicEU;
    AutoSplitKey = true;
    Caption = 'Intrastat Journals';
    DataCaptionFields = "Journal Batch Name";
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Bank,Application,Payroll,Approve,Page';
    SaveValues = true;
    SourceTable = "Intrastat Jnl. Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = BasicEU;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    exit(IntraJnlManagement.LookupName(GetRangeMax("Journal Template Name"), CurrentJnlBatchName, Text));
                end;

                trigger OnValidate()
                begin
                    IntraJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies whether the item was received or shipped by the company.';
                }
                field(Date; Date)
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the date the item entry was posted.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the document number on the entry.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the number of the item.';
                }
                field(Name; Name)
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the name of the item.';
                }
                field("Tariff No."; "Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s tariff number.';
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a description of the item.';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; "Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                    Visible = false;
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Entry/Exit Point"; "Entry/Exit Point")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the code of either the port of entry where the items passed into your country/region or the port of exit.';
                    Visible = false;
                }
                field("Area"; Area)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                    Visible = false;
                }
                field("Supplementary Units"; "Supplementary Units")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if you must report information about quantity and units of measure for this item.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number of units of the item in the entry.';
                }
                field("Net Weight"; "Net Weight")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the net weight of one unit of the item.';
                }
                field("Total Weight"; "Total Weight")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the total weight for the items in the item entry.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the total amount of the entry, excluding VAT.';
                }
                field("Statistical Value"; "Statistical Value")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the entry''s statistical value, which must be reported to the statistics authorities.';
                }
                field("Source Type"; "Source Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the entry type.';
                }
                field("Source Entry No."; "Source Entry No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number that the item entry had in the table it came from.';
                }
                field("Cost Regulation %"; "Cost Regulation %")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies any indirect costs, as a percentage.';
                    Visible = false;
                }
                field("Indirect Cost"; "Indirect Cost")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies an amount that represents the costs for freight and insurance.';
                    Visible = false;
                }
                field("Internal Ref. No."; "Internal Ref. No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a reference number used by the customs and tax authorities.';
                }
                field("Shpt. Method Code"; "Shpt. Method Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the item''s shipment method.';
                }
            }
            group(Control40)
            {
                ShowCaption = false;
                field(StatisticalValue; StatisticalValue + "Statistical Value" - xRec."Statistical Value")
                {
                    ApplicationArea = BasicEU;
                    AutoFormatType = 1;
                    Caption = 'Statistical Value';
                    Editable = false;
                    ToolTip = 'Specifies the statistical value that has accumulated in the Intrastat journal.';
                    Visible = StatisticalValueVisible;
                }
                field("TotalStatisticalValue + ""Statistical Value"" - xRec.""Statistical Value"""; TotalStatisticalValue + "Statistical Value" - xRec."Statistical Value")
                {
                    ApplicationArea = BasicEU;
                    AutoFormatType = 1;
                    Caption = 'Total Stat. Value';
                    Editable = false;
                    ToolTip = 'Specifies the total statistical value in the Intrastat journal.';
                }
            }
        }
        area(factboxes)
        {
            part(ErrorMessagesPart; "Error Messages Part")
            {
                ApplicationArea = BasicEU;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Item)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Item';
                    Image = Item;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View and edit detailed information for the item.';
                }
            }
        }
        area(processing)
        {
            action(GetEntries)
            {
                ApplicationArea = BasicEU;
                Caption = 'Suggest Lines';
                Ellipsis = true;
                Image = SuggestLines;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Suggests Intrastat transactions to be reported and fills in Intrastat journal.';

                trigger OnAction()
                var
                    VATReportsConfiguration: Record "VAT Reports Configuration";
                begin
                    VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"Intrastat Report");
                    if VATReportsConfiguration.FindFirst and (VATReportsConfiguration."Suggest Lines Codeunit ID" <> 0) then begin
                        CODEUNIT.Run(VATReportsConfiguration."Suggest Lines Codeunit ID", Rec);
                        exit;
                    end;

                    GetItemEntries.SetIntrastatJnlLine(Rec);
                    GetItemEntries.RunModal;
                    Clear(GetItemEntries);
                end;
            }
            action(ChecklistReport)
            {
                ApplicationArea = BasicEU;
                Caption = 'Checklist Report';
                Image = PrintChecklistReport;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Validate the Intrastat journal lines.';

                trigger OnAction()
                var
                    VATReportsConfiguration: Record "VAT Reports Configuration";
                begin
                    VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"Intrastat Report");
                    if VATReportsConfiguration.FindFirst and (VATReportsConfiguration."Validate Codeunit ID" <> 0) then begin
                        CODEUNIT.Run(VATReportsConfiguration."Validate Codeunit ID", Rec);
                        exit;
                    end;

                    ReportPrint.PrintIntrastatJnlLine(Rec);
                end;
            }
            action("Toggle Error Filter")
            {
                ApplicationArea = BasicEU;
                Caption = 'Filter Error Lines';
                Image = "Filter";
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Show or hide Intrastat journal lines that do not have errors.';

                trigger OnAction()
                begin
                    MarkedOnly(not MarkedOnly);
                end;
            }
            action(CreateFile)
            {
                ApplicationArea = BasicEU;
                Caption = 'Create File';
                Ellipsis = true;
                Image = MakeDiskette;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Create the Intrastat reporting file.';

                trigger OnAction()
                var
                    VATReportsConfiguration: Record "VAT Reports Configuration";
                begin
                    VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"Intrastat Report");
                    if VATReportsConfiguration.FindFirst and (VATReportsConfiguration."Validate Codeunit ID" <> 0) and
                       (VATReportsConfiguration."Content Codeunit ID" <> 0)
                    then begin
                        CODEUNIT.Run(VATReportsConfiguration."Validate Codeunit ID", Rec);
                        if ErrorsExistOnCurrentBatch(true) then
                            Error('');
                        Commit();

                        CODEUNIT.Run(VATReportsConfiguration."Content Codeunit ID", Rec);
                        exit;
                    end;

                    ReportPrint.PrintIntrastatJnlLine(Rec);
                    if ErrorsExistOnCurrentBatch(true) then
                        Error('');
                    Commit();

                    IntrastatJnlLine.CopyFilters(Rec);
                    IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    IntrastatJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                    REPORT.Run(REPORT::"Intrastat - Make Disk Tax Auth", true, false, IntrastatJnlLine);
                end;
            }
            action(Form)
            {
                ApplicationArea = BasicEU;
                Caption = 'Prints Intrastat Journal';
                Ellipsis = true;
                Image = PrintForm;
                Promoted = true;
                PromotedCategory = "Report";
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Print that Form - this is used to print Intrastat journal.';

                trigger OnAction()
                begin
                    IntrastatJnlLine.CopyFilters(Rec);
                    IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                    IntrastatJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                    REPORT.Run(REPORT::"Intrastat - Form", true, false, IntrastatJnlLine);
                end;
            }
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    Promoted = true;
                    PromotedCategory = Category8;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditJournalWorksheetInExcel(CurrPage.Caption, CurrPage.ObjectId(false), "Journal Batch Name", "Journal Template Name");
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::ODataV4 then
            UpdateStatisticalValue;
        UpdateErrors;
    end;

    trigger OnInit()
    begin
        StatisticalValueVisible := true;
    end;

    trigger OnOpenPage()
    var
        ServerSetting: Codeunit "Server Setting";
        JnlSelected: Boolean;
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        if ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::ODataV4 then
            exit;

        if IsOpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            IntraJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        IntraJnlManagement.TemplateSelection(PAGE::"Intrastat Journal", Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        IntraJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);

        LineStyleExpression := 'Standard';
    end;

    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        GetItemEntries: Report "Get Item Ledger Entries";
        ReportPrint: Codeunit "Test Report-Print";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        ClientTypeManagement: Codeunit "Client Type Management";
        LineStyleExpression: Text;
        StatisticalValue: Decimal;
        TotalStatisticalValue: Decimal;
        CurrentJnlBatchName: Code[10];
        ShowStatisticalValue: Boolean;
        ShowTotalStatisticalValue: Boolean;
        [InDataSet]
        StatisticalValueVisible: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;

    local procedure UpdateStatisticalValue()
    begin
        IntraJnlManagement.CalcStatisticalValue(
          Rec, xRec, StatisticalValue, TotalStatisticalValue,
          ShowStatisticalValue, ShowTotalStatisticalValue);
        StatisticalValueVisible := ShowStatisticalValue;
        StatisticalValueVisible := ShowTotalStatisticalValue;
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        IntraJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure ErrorsExistOnCurrentBatch(ShowError: Boolean): Boolean
    var
        ErrorMessage: Record "Error Message";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ErrorMessage.SetContext(IntrastatJnlBatch);
        exit(ErrorMessage.HasErrors(ShowError));
    end;

    local procedure ErrorsExistOnCurrentLine(): Boolean
    var
        ErrorMessage: Record "Error Message";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
        ErrorMessage.SetContext(IntrastatJnlBatch);
        exit(ErrorMessage.HasErrorMessagesRelatedTo(Rec));
    end;

    local procedure UpdateErrors()
    begin
        CurrPage.ErrorMessagesPart.PAGE.SetRecordID(RecordId);
        CurrPage.ErrorMessagesPart.PAGE.GetStyleOfRecord(Rec, LineStyleExpression);
        Mark(ErrorsExistOnCurrentLine);
    end;
}

