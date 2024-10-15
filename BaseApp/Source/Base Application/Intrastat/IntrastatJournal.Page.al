page 311 "Intrastat Journal"
{
    ApplicationArea = BasicEU;
    AutoSplitKey = true;
    Caption = 'Intrastat Journals';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
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
                ToolTip = 'Specifies the name of the journal batch.';

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
                    ToolTip = 'Specifies whether the item was received or shipped by the company.';
                }
                field("Reference Period"; "Reference Period")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    ToolTip = 'Specifies the reference period.';
                }
                field(Date; Date)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the date the item entry was posted.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the document number on the entry.';
                    ShowMandatory = true;
                }
                field("VAT Registration No."; "VAT Registration No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies VAT registration number that is associated with the Intrastat journal.';
                    ObsoleteState = Pending;
                    ObsoleteReason = 'Merged to W1';
                    ObsoleteTag = '18.0';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number of the item.';
                }
                field(Name; Name)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the item.';
                    Caption = 'Item Name';
                }
                field("Service Tariff No."; "Service Tariff No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the ID of the service tariff that is associated with the Intrastat journal.';
                }
                field("Payment Method"; "Payment Method")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the payment method that is associated with the Intrastat journal.';
                }
                field("Custom Office No."; "Custom Office No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the customs office that the trade of goods or services passes through.';
                }
                field("Corrected Intrastat Report No."; "Corrected Intrastat Report No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number of the corrected Intrastat report that is associated with the Intrastat journal.';
                }
                field("Corrected Document No."; "Corrected Document No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the document number of the corrected Intrastat journal entry.';
                }
                field("Tariff No."; "Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s tariff number.';
                }
                field("Item Description"; "Item Description")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the tariff no. that is associated with the item.';
                    Caption = 'Tariff No. Description';
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the country/region code for the item entry.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        if PAGE.RunModal(10, Country) = ACTION::LookupOK then
                            "Country/Region Code" := Country."Intrastat Code";
                    end;
                }
                field("Partner VAT ID"; "Partner VAT ID")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the counter party''s VAT number.';
                }
                field("Country/Region of Origin Code"; "Country/Region of Origin Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the country/region code of the place of origin of the item.';
                }
                field("Country/Region of Payment Code"; "Country/Region of Payment Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the country/region of the payment method that is associated with the Intrastat journal.';
                }
                field("Area"; Area)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the code for the area of the customer or vendor with which you traded the items on this journal line.';
                }
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transaction type for the item entry.';
                }
                field("Transaction Specification"; "Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transaction specification code for the item transaction on this journal line.';
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transport method for the item entry.';
                }
                field("Entry/Exit Point"; "Entry/Exit Point")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the code of either the port of entry where the items passed into your country/region or the port of exit.';
                    Visible = true;
                }
                field("Group Code"; "Group Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the group code that corresponds with the Intrastat journal.';
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
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the currency code that is associated with the Intrastat journal entry.';
                }
                field("Total Weight"; GetFormattedTotalWeight)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Total Weight';
                    ToolTip = 'Specifies the total weight for the items in the item entry.';
                }
                field("Source Currency Amount"; "Source Currency Amount")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the amount in the currency of the source of the transaction.';
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

                    trigger OnValidate()
                    begin
                        SourceEntryNoEditable := "Source Type" = "Source Type"::"VAT Entry"
                    end;
                }
                field("Source Entry No."; "Source Entry No.")
                {
                    ApplicationArea = BasicEU;
                    Editable = SourceEntryNoEditable;
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
                field("Progressive No."; "Progressive No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the progressive number.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
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
                action(Card)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View and edit detailed information for the item.';
                }
            }
        }
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                Image = Print;
                action("&Quarterly Report")
                {
                    ApplicationArea = BasicEU;
                    Caption = '&Quarterly Report';
                    Ellipsis = true;
                    Image = "Report";
                    ToolTip = 'Print the quarterly Intrastat report.';

                    trigger OnAction()
                    begin
                        IntrastatJnlLine.CopyFilters(Rec);
                        IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                        IntrastatJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                        REPORT.Run(Report::"Intrastat - Quarterly Report", true, false, IntrastatJnlLine);
                    end;
                }
                action("&Monthly Report")
                {
                    ApplicationArea = BasicEU;
                    Caption = '&Monthly Report';
                    Ellipsis = true;
                    Image = "Report";
                    ToolTip = 'View the monthly report.';

                    trigger OnAction()
                    begin
                        IntrastatJnlLine.CopyFilters(Rec);
                        IntrastatJnlLine.SetRange("Journal Template Name", "Journal Template Name");
                        IntrastatJnlLine.SetRange("Journal Batch Name", "Journal Batch Name");
                        REPORT.Run(Report::"Intrastat - Monthly Report", true, false, IntrastatJnlLine);
                    end;
                }
                action(CreateFile)
                {
                    ApplicationArea = BasicEU;
                    Caption = 'Create File';
                    Ellipsis = true;
                    Image = MakeDiskette;
                    ToolTip = 'Export the Intrastat report to a text file.';

                    trigger OnAction()
                    var
                        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
                        MakeDiskReport: Report "Intrastat - Make Disk Tax Auth";
                    begin
		    	        FeatureTelemetry.LogUptake('0000FAF', IntrastatTok, Enum::"Feature Uptake Status"::Used);
                        IntrastatJnlBatch.SetRange("Journal Template Name", "Journal Template Name");
                        IntrastatJnlBatch.SetRange(Name, "Journal Batch Name");
                        MakeDiskReport.SetTableView(IntrastatJnlBatch);
                        MakeDiskReport.Run;
			            FeatureTelemetry.LogUsage('0000QWE', IntrastatTok, 'File created');
                    end;
                }
            }
            action(GetEntries)
            {
                ApplicationArea = BasicEU;
                Caption = '&Get Entries';
                Ellipsis = true;
                Image = GetEntries;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    VATReportsConfiguration: Record "VAT Reports Configuration";
                begin
                    if FindVATReportsConfiguration(VATReportsConfiguration) and
                        (VATReportsConfiguration."Suggest Lines Codeunit ID" <> 0)
                    then begin
                        CODEUNIT.Run(VATReportsConfiguration."Suggest Lines Codeunit ID", Rec);
                        exit;
                    end;

                    GetItemEntries.SetIntrastatJnlLine(Rec);
                    GetItemEntries.RunModal;
                    Clear(GetItemEntries);
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

    trigger OnAfterGetRecord()
    begin
        UpdateErrors();
        SourceEntryNoEditable := "Source Type" = "Source Type"::"VAT Entry";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if ClientTypeManagement.GetCurrentClientType <> CLIENTTYPE::ODataV4 then
            UpdateStatisticalValue;
        UpdateErrors();
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
        FeatureTelemetry.LogUptake('0000FAS', IntrastatTok, Enum::"Feature Uptake Status"::Discovered);
        Commit();
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
        IntraJnlManagement: Codeunit IntraJnlManagement;
        ClientTypeManagement: Codeunit "Client Type Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        LineStyleExpression: Text;
        IntrastatTok: Label 'Intrastat', Locked = true;
        StatisticalValue: Decimal;
        TotalStatisticalValue: Decimal;
        CurrentJnlBatchName: Code[10];
        ShowStatisticalValue: Boolean;
        ShowTotalStatisticalValue: Boolean;
        Country: Record "Country/Region";
        [InDataSet]
        SourceEntryNoEditable: Boolean;
        [InDataSet]
        StatisticalValueVisible: Boolean;
        IsSaaSExcelAddinEnabled: Boolean;

    local procedure FindVATReportsConfiguration(var VATReportsConfiguration: Record "VAT Reports Configuration"): Boolean
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", "VAT Report Configuration"::"Intrastat Report");
        OnBeforeFindVATReportsConfiguration(Rec, VATReportsConfiguration);
        exit(VATReportsConfiguration.FindFirst());
    end;

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
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateErrors(IsHandled, Rec);
        if IsHandled then
            exit;

        CurrPage.ErrorMessagesPart.PAGE.SetRecordID(Rec.RecordId);
        CurrPage.ErrorMessagesPart.PAGE.GetStyleOfRecord(Rec, LineStyleExpression);
        Rec.Mark(ErrorsExistOnCurrentLine());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindVATReportsConfiguration(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var VATReportsConfiguration: Record "VAT Reports Configuration")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeUpdateErrors(var IsHandled: boolean; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;
}

