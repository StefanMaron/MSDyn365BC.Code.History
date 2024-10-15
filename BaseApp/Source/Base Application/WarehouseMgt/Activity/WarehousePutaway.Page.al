namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

page 5770 "Warehouse Put-away"
{
    Caption = 'Warehouse Put-away';
    InsertAllowed = false;
    PageType = Document;
    RefreshOnActivate = true;
    SaveValues = true;
    SourceTable = "Warehouse Activity Header";
    SourceTableView = where(Type = const("Put-away"));

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(CurrentLocationCode; CurrentLocationCode)
                {
                    ApplicationArea = Location;
                    Caption = 'Location Code';
                    Editable = false;
                    Lookup = false;
                    ToolTip = 'Specifies the location where the warehouse activity takes place. ';
                }
                field("Breakbulk Filter"; Rec."Breakbulk Filter")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies that the intermediate Take and Place lines will not show as put-away, pick, or movement lines, when the quantity in the larger unit of measure is being put-away, picked or moved completely.';

                    trigger OnValidate()
                    begin
                        BreakbulkFilterOnAfterValidate();
                    end;
                }
                field("Assigned User ID"; Rec."Assigned User ID")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the ID of the user who is responsible for the document.';
                }
                field("Assignment Date"; Rec."Assignment Date")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the date when the user was assigned the activity.';
                }
                field("Assignment Time"; Rec."Assignment Time")
                {
                    ApplicationArea = Warehouse;
                    Editable = false;
                    ToolTip = 'Specifies the time when the user was assigned the activity.';
                }
                field("Sorting Method"; Rec."Sorting Method")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the method by which the lines are sorted on the warehouse header, such as Item or Document.';

                    trigger OnValidate()
                    begin
                        SortingMethodOnAfterValidate();
                    end;
                }
            }
            part(WhseActivityLines; "Whse. Put-away Subform")
            {
                ApplicationArea = Warehouse;
                SubPageLink = "Activity Type" = field(Type),
                              "No." = field("No.");
                SubPageView = sorting("Activity Type", "No.", "Sorting Sequence No.")
                              where(Breakbulk = const(false));
            }
        }
        area(factboxes)
        {
            part(Control1901796907; "Item Warehouse FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseActivityLines;
                SubPageLink = "No." = field("Item No.");
                Visible = true;
            }
            part(Control5; "Lot Numbers by Bin FactBox")
            {
                ApplicationArea = Warehouse;
                Provider = WhseActivityLines;
                SubPageLink = "Item No." = field("Item No."),
                              "Variant Code" = field("Variant Code"),
                              "Location Code" = field("Location Code");
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Put-&away")
            {
                Caption = 'Put-&away';
                Image = CreatePutAway;
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Warehouse Comment Sheet";
                    RunPageLink = "Table Name" = const("Whse. Activity Header"),
                                  Type = field(Type),
                                  "No." = field("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action("Registered Put-aways")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Registered Put-aways';
                    Image = RegisteredDocs;
                    RunObject = Page "Registered Whse. Activity List";
                    RunPageLink = Type = field(Type),
                                  "Whse. Activity No." = field("No.");
                    RunPageView = sorting("Whse. Activity No.");
                    ToolTip = 'View the quantity that has already been put-away.';
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Autofill Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Autofill Qty. to Handle';
                    Image = AutofillQtyToHandle;
                    ToolTip = 'Have the system enter the outstanding quantity in the Qty. to Handle field.';

                    trigger OnAction()
                    begin
                        AutofillQtyToHandle();
                    end;
                }
                action("Delete Qty. to Handle")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Delete Qty. to Handle';
                    Image = DeleteQtyToHandle;
                    ToolTip = 'Have the system clear the value in the Qty. To Handle field. ';

                    trigger OnAction()
                    begin
                        DeleteQtyToHandle();
                    end;
                }
                separator(Action23)
                {
                }
            }
            group("&Registering")
            {
                Caption = '&Registering';
                Image = PostOrder;
                action("&Register Put-away")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Register Put-away';
                    Image = RegisterPutAway;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record that the items have been put away.';

                    trigger OnAction()
                    begin
                        RegisterPutAwayYesNo();
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Warehouse;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    WhseActPrint.PrintPutAwayHeader(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref("&Register Put-away_Promoted"; "&Register Put-away")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                group("Category_Qty. to Handle")
                {
                    Caption = 'Qty. to Handle';
                    ShowAs = SplitButton;

                    actionref("Autofill Qty. to Handle_Promoted"; "Autofill Qty. to Handle")
                    {
                    }
                    actionref("Delete Qty. to Handle_Promoted"; "Delete Qty. to Handle")
                    {
                    }
                }
                actionref("Registered Put-aways_Promoted"; "Registered Put-aways")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CurrentLocationCode := Rec."Location Code";
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.Update();
    end;

    trigger OnOpenPage()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        Rec.ErrorIfUserIsNotWhseEmployee();
        Rec.FilterGroup(2); // set group of filters user cannot change
        Rec.SetFilter("Location Code", WMSManagement.GetWarehouseEmployeeLocationFilter(UserId));
        Rec.FilterGroup(0); // set filter group back to standard

        SetBinFieldsVisibleOnLines(false);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        SetBinFieldsVisibleOnLines(true);
    end;

    var
        WhseActPrint: Codeunit "Warehouse Document-Print";
        CurrentLocationCode: Code[10];
        HideBinFields: Boolean;
        LocationCodeWhenHideBinLastChecked: Code[20];

    local procedure SetBinFieldsVisibleOnLines(AllowSubformUpdate: Boolean)
    var
        BinVisiblityNeedsUpdate: Boolean;
    begin
        BinVisiblityNeedsUpdate := CheckBinFieldsVisibility();
        CurrPage.WhseActivityLines.Page.SetHideBinFields(HideBinFields);

        if not BinVisiblityNeedsUpdate or not AllowSubFormUpdate then
            exit;

        CurrPage.WhseActivityLines.Page.Update(false); // Visibility on the subform must be updated via. page update, since fields are in repeater
    end;

    local procedure CheckBinFieldsVisibility() BinVisiblityNeedsUpdate: Boolean
    var
        HideBinFieldsLocal: Boolean;
    begin
        if (Rec."Location Code" = LocationCodeWhenHideBinLastChecked) then
            exit(false);

        if Rec."Location Code" <> '' then
            HideBinFieldsLocal := not Rec.BinCodeMandatory();

        LocationCodeWhenHideBinLastChecked := Rec."Location Code";
        BinVisiblityNeedsUpdate := HideBinFieldsLocal <> HideBinFields;
        HideBinFields := HideBinFieldsLocal;
    end;

    local procedure AutofillQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.AutofillQtyToHandle();
    end;

    local procedure DeleteQtyToHandle()
    begin
        CurrPage.WhseActivityLines.PAGE.DeleteQtyToHandle();
    end;

    local procedure RegisterPutAwayYesNo()
    begin
        CurrPage.WhseActivityLines.PAGE.RegisterPutAwayYesNo();
    end;

    local procedure SortingMethodOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure BreakbulkFilterOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

