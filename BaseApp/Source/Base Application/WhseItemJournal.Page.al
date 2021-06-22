page 7324 "Whse. Item Journal"
{
    AdditionalSearchTerms = 'increase inventory,decrease inventory,adjust inventory';
    ApplicationArea = Warehouse;
    AutoSplitKey = true;
    Caption = 'Warehouse Item Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Line,Item';
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
                    CurrPage.SaveRecord;
                    LookupName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    CheckName(CurrentJnlBatchName, CurrentLocationCode, Rec);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            field(CurrentLocationCode; CurrentLocationCode)
            {
                ApplicationArea = Warehouse;
                Caption = 'Location Code';
                Editable = false;
                Lookup = true;
                TableRelation = Location;
                ToolTip = 'Specifies the code for the location where the warehouse activity takes place.';
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Registering Date"; "Registering Date")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date the line is registered.';
                }
                field("Whse. Document No."; "Whse. Document No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the warehouse document number of the journal line.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item on the journal line.';

                    trigger OnValidate()
                    begin
                        GetItem("Item No.", ItemDescription);
                    end;
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Zone Code"; "Zone Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the zone code where the bin on this line is located.';
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of units of the item in the adjustment (positive or negative) or the reclassification.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Reason Code"; "Reason Code")
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
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Shift+Ctrl+I';
                    ToolTip = 'View or edit serial numbers and lot numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        OpenItemTrackingLines;
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
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Item Card";
                    RunPageLink = "No." = FIELD("Item No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
                action("Warehouse Entries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Warehouse Entries';
                    Image = BinLedger;
                    RunObject = Page "Warehouse Entries";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    RunPageView = SORTING("Item No.", "Location Code", "Variant Code");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View completed warehouse activities related to the document.';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Ledger E&ntries';
                    Image = ItemLedger;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Item Ledger Entries";
                    RunPageLink = "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code"),
                                  "Location Code" = FIELD("Location Code");
                    RunPageView = SORTING("Item No.");
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
                action("Bin Contents")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Bin Contents';
                    Image = BinContent;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Page "Bin Contents List";
                    RunPageLink = "Location Code" = FIELD("Location Code"),
                                  "Item No." = FIELD("Item No."),
                                  "Variant Code" = FIELD("Variant Code");
                    RunPageView = SORTING("Location Code", "Item No.", "Variant Code");
                    ToolTip = 'View items in the bin if the selected line contains a bin code.';
                }
                action("Reservation Entries")
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    RunObject = Page "Reservation Entries";
                    RunPageLink = "Reservation Status" = CONST(Reservation),
                                  "Item No." = FIELD("Item No.");
                    RunPageView = SORTING("Item No.", "Variant Code", "Location Code", "Reservation Status", "Shipment Date", "Expected Receipt Date", "Serial No.", "Lot No.");
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';
                }
            }
        }
        area(processing)
        {
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
                action("&Register")
                {
                    ApplicationArea = Warehouse;
                    Caption = '&Register';
                    Image = Confirm;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F9';
                    ToolTip = 'Register the warehouse entry in question, such as a positive adjustment. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register", Rec);
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
                action("Register and &Print")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Register and &Print';
                    Image = ConfirmAndPrint;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Register the warehouse entry adjustments and print an overview of the changes. ';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register+Print", Rec);
                        CurrentJnlBatchName := GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetItem("Item No.", ItemDescription);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetUpNewLine(xRec);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        if IsOpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            CurrentLocationCode := "Location Code";
            OpenJnl(CurrentJnlBatchName, CurrentLocationCode, Rec);
            exit;
        end;
        TemplateSelection(PAGE::"Whse. Item Journal", 0, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        OpenJnl(CurrentJnlBatchName, CurrentLocationCode, Rec);
    end;

    var
        ReportPrint: Codeunit "Test Report-Print";
        CurrentJnlBatchName: Code[10];
        CurrentLocationCode: Code[10];
        ItemDescription: Text[100];

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        SetName(CurrentJnlBatchName, CurrentLocationCode, Rec);
        CurrPage.Update(false);
    end;
}

