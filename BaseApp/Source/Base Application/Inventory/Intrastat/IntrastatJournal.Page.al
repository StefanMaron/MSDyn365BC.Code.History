#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Finance.VAT.Reporting;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Telemetry;
using System.Utilities;

page 311 "Intrastat Journal"
{
    ApplicationArea = BasicEU;
    AutoSplitKey = true;
    Caption = 'Intrastat Journals';
    DataCaptionFields = "Journal Batch Name";
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Intrastat Jnl. Line";
    UsageCategory = Tasks;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

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
                    exit(IntraJnlManagement.LookupName(Rec.GetRangeMax("Journal Template Name"), CurrentJnlBatchName, Text));
                end;

                trigger OnValidate()
                begin
                    IntraJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies whether the item was received or shipped by the company.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the date the item entry was posted.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the document number on the entry.';
                    ShowMandatory = true;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the number of the item.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = BasicEU;
                    StyleExpr = LineStyleExpression;
                    ToolTip = 'Specifies the name of the item.';
                    Caption = 'Item Name';
                }
                field("Tariff No."; Rec."Tariff No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item''s tariff number.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the name of the tariff no. that is associated with the item.';
                    Caption = 'Tariff No. Description';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Partner VAT ID"; Rec."Partner VAT ID")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the counter party''s VAT number.';
                }
                field("Country/Region of Origin Code"; Rec."Country/Region of Origin Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a code for the country/region where the item was produced or processed.';
                }
                field("Area"; Rec.Area)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                    Visible = false;
                }
                field("Transaction Type"; Rec."Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; Rec."Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                    Visible = false;
                }
                field("Transport Method"; Rec."Transport Method")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Entry/Exit Point"; Rec."Entry/Exit Point")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the code of either the port of entry where the items passed into your country/region or the port of exit.';
                    Visible = false;
                }
                field("Supplementary Units"; Rec."Supplementary Units")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies if you must report information about quantity and units of measure for this item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number of units of the item in the entry.';
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the net weight of one unit of the item.';
                }
                field("Total Weight"; Rec."Total Weight")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the total weight for the items in the item entry.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the total amount of the entry, excluding VAT.';
                }
                field("Statistical Value"; Rec."Statistical Value")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the entry''s statistical value, which must be reported to the statistics authorities.';
                }
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the entry type.';
                }
                field("Source Entry No."; Rec."Source Entry No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the number that the item entry had in the table it came from.';
                }
                field("Cost Regulation %"; Rec."Cost Regulation %")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies any indirect costs, as a percentage.';
                    Visible = false;
                }
                field("Indirect Cost"; Rec."Indirect Cost")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies an amount that represents the costs for freight and insurance.';
                    Visible = false;
                }
                field("Internal Ref. No."; Rec."Internal Ref. No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies a reference number used by the customs and tax authorities.';
                }
                field("Shpt. Method Code"; Rec."Shpt. Method Code")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the item''s shipment method.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the location that the entry is linked to.';
                }
            }
            group(Control40)
            {
                ShowCaption = false;
                field(StatisticalValue; StatisticalValue + Rec."Statistical Value" - xRec."Statistical Value")
                {
                    ApplicationArea = BasicEU;
                    AutoFormatType = 1;
                    Caption = 'Statistical Value';
                    Editable = false;
                    ToolTip = 'Specifies the statistical value that has accumulated in the Intrastat journal.';
                    Visible = StatisticalValueVisible;
                }
#pragma warning disable AA0100
                field("TotalStatisticalValue + ""Statistical Value"" - xRec.""Statistical Value"""; TotalStatisticalValue + Rec."Statistical Value" - xRec."Statistical Value")
#pragma warning restore AA0100
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
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
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
                ToolTip = 'Suggests Intrastat transactions to be reported and fills in Intrastat journal.';

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
                    GetItemEntries.RunModal();
                    Clear(GetItemEntries);
                end;
            }
            action(ChecklistReport)
            {
                ApplicationArea = BasicEU;
                Caption = 'Checklist Report';
                Image = PrintChecklistReport;
                ToolTip = 'Validate the Intrastat journal lines.';

                trigger OnAction()
                var
                    VATReportsConfiguration: Record "VAT Reports Configuration";
                begin
                    if FindVATReportsConfiguration(VATReportsConfiguration) and
                        (VATReportsConfiguration."Validate Codeunit ID" <> 0)
                    then begin
                        CODEUNIT.Run(VATReportsConfiguration."Validate Codeunit ID", Rec);
                        CurrPage.Update();
                        exit;
                    end;

                    ReportPrint.PrintIntrastatJnlLine(Rec);
                    CurrPage.Update();
                end;
            }
            action("Toggle Error Filter")
            {
                ApplicationArea = BasicEU;
                Caption = 'Filter Error Lines';
                Image = "Filter";
                ToolTip = 'Show or hide Intrastat journal lines that do not have errors.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(not Rec.MarkedOnly);
                end;
            }
            action(CreateFile)
            {
                ApplicationArea = BasicEU;
                Caption = 'Create File';
                Ellipsis = true;
                Image = MakeDiskette;
                ToolTip = 'Create the Intrastat reporting file.';

                trigger OnAction()
                var
                    VATReportsConfiguration: Record "VAT Reports Configuration";
                begin
                    FeatureTelemetry.LogUptake('0000FAF', IntrastatTok, Enum::"Feature Uptake Status"::Used);
                    Commit();

                    if FindVATReportsConfiguration(VATReportsConfiguration) and
                        (VATReportsConfiguration."Validate Codeunit ID" <> 0) and
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
                    IntrastatJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                    IntrastatJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                    REPORT.Run(REPORT::"Intrastat - Make Disk Tax Auth", true, false, IntrastatJnlLine);
                    FeatureTelemetry.LogUsage('0000QWE', IntrastatTok, 'File created');
                end;
            }
            action(Form)
            {
                ApplicationArea = BasicEU;
                Caption = 'Print Intrastat Journal';
                Ellipsis = true;
                Image = PrintForm;
                ToolTip = 'Print the intrastat journal.';

                trigger OnAction()
                begin
                    IntrastatJnlLine.CopyFilters(Rec);
                    IntrastatJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                    IntrastatJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
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
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        ODataUtility: Codeunit ODataUtility;
                    begin
                        ODataUtility.EditJournalWorksheetInExcel(CurrPage.Caption, CurrPage.ObjectId(false), Rec."Journal Batch Name", Rec."Journal Template Name");
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(GetEntries_Promoted; GetEntries)
                {
                }
                actionref(CreateFile_Promoted; CreateFile)
                {
                }
                actionref(ChecklistReport_Promoted; ChecklistReport)
                {
                }
                actionref("Toggle Error Filter_Promoted"; "Toggle Error Filter")
                {
                }
                actionref(Item_Promoted; Item)
                {
                }
            }
            group(Category_Category7)
            {
                Caption = 'Approve', Comment = 'Generated from the PromotedActionCategories property index 6.';
            }
            group(Category_Category4)
            {
                Caption = 'Bank', Comment = 'Generated from the PromotedActionCategories property index 3.';
            }
            group(Category_Category5)
            {
                Caption = 'Application', Comment = 'Generated from the PromotedActionCategories property index 4.';
            }
            group(Category_Category6)
            {
                Caption = 'Payroll', Comment = 'Generated from the PromotedActionCategories property index 5.';
            }
            group(Category_Category8)
            {
                Caption = 'Page', Comment = 'Generated from the PromotedActionCategories property index 7.';

                actionref(EditInExcel_Promoted; EditInExcel)
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';

                actionref(Form_Promoted; Form)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateErrors();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::ODataV4 then
            UpdateStatisticalValue();
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
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;

        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
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
        FeatureTelemetry: Codeunit "Feature Telemetry";
        LineStyleExpression: Text;
        IntrastatTok: Label 'Intrastat', Locked = true;
        StatisticalValue: Decimal;
        TotalStatisticalValue: Decimal;
        CurrentJnlBatchName: Code[10];
        ShowStatisticalValue: Boolean;
        ShowTotalStatisticalValue: Boolean;
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
        CurrPage.SaveRecord();
        IntraJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;

    local procedure ErrorsExistOnCurrentBatch(ShowError: Boolean): Boolean
    var
        ErrorMessage: Record "Error Message";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        ErrorMessage.SetContext(IntrastatJnlBatch);
        exit(ErrorMessage.HasErrors(ShowError));
    end;

    local procedure ErrorsExistOnCurrentLine(): Boolean
    var
        ErrorMessage: Record "Error Message";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
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
#endif
