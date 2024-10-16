﻿namespace Microsoft.Warehouse.Journal;

using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using System.Environment;
using System.Environment.Configuration;
using System.Integration;
using System.Integration.Excel;

page 7365 "Whse. Reclassification Journal"
{
    AdditionalSearchTerms = 'change bin,change zone';
    ApplicationArea = Warehouse;
    AutoSplitKey = true;
    Caption = 'Warehouse Reclassification Journals';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Warehouse Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Warehouse;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    Rec.LookupName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    Rec.CheckName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            field(CurrentLocationCode; CurrentLocationCode)
            {
                ApplicationArea = Location;
                Caption = 'Location Code';
                Editable = false;
                Lookup = true;
                TableRelation = Location;
                ToolTip = 'Specifies the location where the warehouse activity takes place. ';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Registering Date"; Rec."Registering Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date the line is registered.';
                }
                field("Whse. Document No."; Rec."Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Whse. Document No.';
                    ToolTip = 'Specifies the warehouse document number of the journal line.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item on the journal line.';

                    trigger OnValidate()
                    begin
                        Rec.GetItem(Rec."Item No.", ItemDescription);
                    end;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("From Zone Code"; Rec."From Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone from which the item on the journal line is taken.';
                }
                field("From Bin Code"; Rec."From Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin from which the item on the journal line is taken.';
                }
                field("To Zone Code"; Rec."To Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the zone to which the item on the journal line will be moved.';
                }
                field("To Bin Code"; Rec."To Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the bin to which the item on the journal line will be moved.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    MinValue = 0;
                    ToolTip = 'Specifies the number of units of the item in the adjustment (positive or negative) or the reclassification.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Reason Code';
                    ToolTip = 'Specifies the reason code for the warehouse journal line.';
                    Visible = false;
                }
            }
            group(Control22)
            {
                ShowCaption = false;
                fixed(Control1900669001)
                {
                    ShowCaption = false;
                    group("Item Description")
                    {
                        Caption = 'Item Description';
                        field(ItemDescription; ItemDescription)
                        {
                            ApplicationArea = Warehouse;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                }
            }
        }
        area(factboxes)
        {
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(ItemTrackingLines)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
            group("&Item")
            {
                Caption = '&Item';
                Image = Item;
                action(Card)
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = field("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Entries';
                    Image = BinLedger;
                    RunObject = Page "Warehouse Entries";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Location Code" = field("Location Code");
                    RunPageView = sorting("Item No.", "Location Code", "Variant Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View completed warehouse activities related to the document.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Ledger E&ntries';
                    Image = ItemLedger;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code"),
                                  "Location Code" = field("Location Code");
                    RunPageView = sorting("Item No.");
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = field("Location Code"),
                                  "Item No." = field("Item No."),
                                  "Variant Code" = field("Variant Code");
                    RunPageView = sorting("Location Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
            }
        }
        area(processing)
        {
            group("Page")
            {
                Caption = 'Page';
                action(EditInExcel)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit in Excel';
                    Image = Excel;
                    ToolTip = 'Send the data in the journal to an Excel file for analysis or editing.';
                    Visible = IsSaaSExcelAddinEnabled;
                    AccessByPermission = System "Allow Action Export To Excel" = X;

                    trigger OnAction()
                    var
                        EditinExcel: Codeunit "Edit in Excel";
                        EditinExcelFilters: Codeunit "Edit in Excel Filters";
                        ODataUtility: Codeunit "ODataUtility";
                    begin
                        EditinExcelFilters.AddField(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Journal Batch Name")), Enum::"Edit in Excel Filter Type"::Equal, CurrentJnlBatchName, Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddField(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Journal Template Name")), Enum::"Edit in Excel Filter Type"::Equal, Rec."Journal Template Name", Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcelFilters.AddField(ODataUtility.ExternalizeName(Rec.FieldName(Rec."Location Code")), Enum::"Edit in Excel Filter Type"::Equal, CurrentLocationCode, Enum::"Edit in Excel Edm Type"::"Edm.String");
                        EditinExcel.EditPageInExcel(Text.CopyStr(CurrPage.Caption, 1, 240), Page::"Whse. Reclassification Journal", EditInExcelFilters);
                    end;
                }
            }
            group("&Registering")
            {
                Caption = '&Registering';
                Image = PostOrder;
                action("Test Report")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintWhseJnlLine(Rec);
                    end;
                }
                action(Register)
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Register';
                    Image = Confirm;
                    ShortCutKey = 'F9';
                    ToolTip = 'Register the warehouse entry in question, such as a bin code change. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action("Register and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Register and &Print';
                    Image = ConfirmAndPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Register the warehouse entry adjustments and print an overview of the changes. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register+Print", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(Register_Promoted; Register)
                {
                }
                actionref("Register and &Print_Promoted"; "Register and &Print")
                {
                }
                actionref(ItemTrackingLines_Promoted; ItemTrackingLines)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.GetItem(Rec."Item No.", ItemDescription);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.SetUpNewLine(xRec);
    end;

    trigger OnOpenPage()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        ServerSetting: Codeunit "Server Setting";
        JnlSelected: Boolean;
    begin
        IsSaaSExcelAddinEnabled := ServerSetting.GetIsSaasExcelAddinEnabled();
        // if called from API (such as edit-in-excel), do not filter 
        if ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::ODataV4 then
            exit;
        if Rec.IsOpenedFromBatch() then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            CurrentLocationCode := Rec."Location Code";
            Rec.OpenJnl(CurrentJnlBatchName, CurrentLocationCode, Rec);
            exit;
        end;
        JnlSelected := Rec.TemplateSelection(PAGE::"Whse. Reclassification Journal", "Warehouse Journal Template Type"::Reclassification, Rec);
        if not JnlSelected then
            Error('');
        Rec.OpenJnl(CurrentJnlBatchName, CurrentLocationCode, Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        CurrentJnlBatchName: Code[10];
        CurrentLocationCode: Code[10];
        ItemDescription: Text[100];
        IsSaaSExcelAddinEnabled: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        Rec.SetName(CurrentJnlBatchName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;
}

