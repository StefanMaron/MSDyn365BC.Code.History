page 99000886 "Subcontracting Worksheet"
{
    ApplicationArea = Manufacturing;
    AutoSplitKey = true;
    Caption = 'Subcontracting Worksheets';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    PromotedActionCategories = 'New,Process,Report,Line';
    SaveValues = true;
    SourceTable = "Requisition Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch of the subcontracting worksheet.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord;
                    ReqJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    ReqJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Type)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of requisition worksheet line you are creating.';

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                    end;
                }
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                    end;
                }
                field("Accept Action Message"; "Accept Action Message")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies whether to accept the action message proposed for the line.';
                }
                field("Action Message"; "Action Message")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies an action to take to rebalance the demand-supply situation.';
                }
                field("Prod. Order No."; "Prod. Order No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the related production order.';
                }
                field("Operation No."; "Operation No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the operation number for this routing line.';
                }
                field("Work Center No."; "Work Center No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work center number of the journal line.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies text that describes the entry.';
                }
                field("Description 2"; "Description 2")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies additional text describing the entry, or a remark about the requisition worksheet line.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies a code for an inventory location where the items that are being ordered will be registered.';
                    Visible = false;
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of units of the item.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the vendor who will ship the items in the purchase order.';

                    trigger OnValidate()
                    begin
                        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
                    end;
                }
                field("Order Address Code"; "Order Address Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the order address of the related vendor.';
                    Visible = false;
                }
                field("Vendor Item No."; "Vendor Item No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the customer.';
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Manufacturing;
                    AssistEdit = true;
                    ToolTip = 'Specifies the currency code for the requisition lines.';
                    Visible = false;

                    trigger OnAssistEdit()
                    var
                        ChangeExchangeRate: Page "Change Exchange Rate";
                    begin
                        ChangeExchangeRate.SetParameter("Currency Code", "Currency Factor", WorkDate);
                        if ChangeExchangeRate.RunModal = ACTION::OK then
                            Validate("Currency Factor", ChangeExchangeRate.GetParameter);

                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Direct Unit Cost"; "Direct Unit Cost")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the cost of one unit of the selected item or resource.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the discount percentage used to calculate the purchase line discount.';
                    Visible = false;
                }
                field("Order Date"; "Order Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the order date that will apply to the requisition worksheet line.';
                    Visible = false;
                }
                field("Due Date"; "Due Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date when you can expect to receive the items.';
                }
                field("Requester ID"; "Requester ID")
                {
                    ApplicationArea = Manufacturing;
                    LookupPageID = "User Lookup";
                    ToolTip = 'Specifies the ID of the user who is ordering the items on the line.';
                    Visible = false;
                }
                field(Confirmed; Confirmed)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies whether the items on the line have been approved for purchase.';
                    Visible = false;
                }
            }
            group(Control20)
            {
                ShowCaption = false;
                fixed(Control1901776201)
                {
                    ShowCaption = false;
                    group(Control1902759801)
                    {
                        Caption = 'Description';
                        field(Description2; Description2)
                        {
                            ApplicationArea = Manufacturing;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies an additional part of the worksheet description.';
                        }
                    }
                    group("Buy-from Vendor Name")
                    {
                        Caption = 'Buy-from Vendor Name';
                        field(BuyFromVendorName; BuyFromVendorName)
                        {
                            ApplicationArea = Manufacturing;
                            Caption = 'Buy-from Vendor Name';
                            Editable = false;
                            ToolTip = 'Specifies the vendor''s name.';
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
                action(Card)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Card';
                    Image = EditLines;
                    Promoted = true;
                    PromotedCategory = Category4;
                    RunObject = Codeunit "Req. Wksh.-Show Card";
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';
                }
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
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                        CurrPage.SaveRecord;
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate Subcontracts")
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Calculate Subcontracts';
                    Ellipsis = true;
                    Image = Calculate;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Calculate the external work centers that are managed by a supplier under contract.';

                    trigger OnAction()
                    var
                        CalculateSubContract: Report "Calculate Subcontracts";
                    begin
                        CalculateSubContract.SetWkShLine(Rec);
                        CalculateSubContract.RunModal;
                    end;
                }
                action(CarryOutActionMessage)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Carry &Out Action Message';
                    Ellipsis = true;
                    Image = CarryOutActionMessage;
                    Promoted = true;
                    PromotedCategory = Process;
                    ToolTip = 'Use a batch job to help you create actual supply orders from the order proposals.';

                    trigger OnAction()
                    var
                        MakePurchOrder: Report "Carry Out Action Msg. - Req.";
                    begin
                        MakePurchOrder.SetReqWkshLine(Rec);
                        MakePurchOrder.RunModal;
                        Clear(MakePurchOrder);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        ReqJnlManagement.GetDescriptionAndRcptName(Rec, Description2, BuyFromVendorName);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ReqJnlManagement.SetUpNewLine(Rec, xRec);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        OpenedFromBatch := ("Journal Batch Name" <> '') and ("Worksheet Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := "Journal Batch Name";
            ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        ReqJnlManagement.TemplateSelection(PAGE::"Subcontracting Worksheet", false, 1, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        ReqJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        ReqJnlManagement: Codeunit ReqJnlManagement;
        CurrentJnlBatchName: Code[10];
        Description2: Text[100];
        BuyFromVendorName: Text[100];
        OpenedFromBatch: Boolean;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord;
        ReqJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

