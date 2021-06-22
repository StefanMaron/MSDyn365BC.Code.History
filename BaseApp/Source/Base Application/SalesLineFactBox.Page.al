page 9087 "Sales Line FactBox"
{
    Caption = 'Sales Line Details';
    PageType = CardPart;
    SourceTable = "Sales Line";

    layout
    {
        area(content)
        {
            field(ItemNo; ShowNo())
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Item No.';
                Lookup = false;
                ToolTip = 'Specifies the item that is handled on the sales line.';

                trigger OnDrillDown()
                begin
                    SalesInfoPaneMgt.LookupItem(Rec);
                end;
            }
            field("Required Quantity"; "Outstanding Quantity" - "Reserved Quantity")
            {
                ApplicationArea = Reservation;
                Caption = 'Required Quantity';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies how many units of the item are required on the sales line.';
            }
            group(Attachments)
            {
                Caption = 'Attachments';
                field("Attached Doc Count"; "Attached Doc Count")
                {
                    ApplicationArea = All;
                    Caption = 'Documents';
                    ToolTip = 'Specifies the number of attachments.';

                    trigger OnDrillDown()
                    var
                        DocumentAttachmentDetails: Page "Document Attachment Details";
                        RecRef: RecordRef;
                    begin
                        RecRef.GetTable(Rec);
                        DocumentAttachmentDetails.OpenForRecRef(RecRef);
                        DocumentAttachmentDetails.RunModal();
                    end;
                }
            }
            group(Availability)
            {
                Caption = 'Availability';
                field("Shipment Date"; SalesInfoPaneMgt.CalcAvailabilityDate(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Shipment Date';
                    ToolTip = 'Specifies when the items on the sales line must be shipped.';
                }
                field("Item Availability"; SalesInfoPaneMgt.CalcAvailability(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item Availability';
                    DecimalPlaces = 0 : 5;
                    DrillDown = true;
                    ToolTip = 'Specifies how may units of the item on the sales line are available, in inventory or incoming before the shipment date.';

                    trigger OnDrillDown()
                    begin
                        ItemAvailFormsMgt.ShowItemAvailFromSalesLine(Rec, ItemAvailFormsMgt.ByEvent());
                        CurrPage.Update(true);
                    end;
                }
                field("Available Inventory"; SalesInfoPaneMgt.CalcAvailableInventory(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Available Inventory';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies the quantity of the item that is currently in inventory and not reserved for other demand.';
                }
                field("Scheduled Receipt"; SalesInfoPaneMgt.CalcScheduledReceipt(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the assembly component are inbound on purchase orders, transfer orders, assembly orders, firm planned production orders, and released production orders.';
                }
                field("Reserved Receipt"; SalesInfoPaneMgt.CalcReservedRequirements(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Receipt';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies how many units of the item on the sales line are reserved on incoming receipts.';
                }
                field("Gross Requirements"; SalesInfoPaneMgt.CalcGrossRequirements(Rec))
                {
                    ApplicationArea = Service;
                    Caption = 'Gross Requirements';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies, for the item on the sales line, dependent demand plus independent demand. Dependent demand comes production order components of all statuses, assembly order components, and planning lines. Independent demand comes from sales orders, transfer orders, service orders, job tasks, and demand forecasts.';
                }
                field("Reserved Requirements"; SalesInfoPaneMgt.CalcReservedDemand(Rec))
                {
                    ApplicationArea = Reservation;
                    Caption = 'Reserved Requirements';
                    DecimalPlaces = 0 : 5;
                    ToolTip = 'Specifies, for the item on the sales line, how many are reserved on demand records.';
                }
            }
            group(Item)
            {
                Caption = 'Item';
                field(UnitofMeasureCode; "Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Unit of Measure Code';
                    ToolTip = 'Specifies the unit of measure that is used to determine the value in the Unit Price field on the sales line.';
                }
                field("Qty. per Unit of Measure"; "Qty. per Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Qty. per Unit of Measure';
                    ToolTip = 'Specifies an auto-filled number if you have included Sales Unit of Measure on the item card and a quantity in the Qty. per Unit of Measure field.';
                }
                field(Substitutions; SalesInfoPaneMgt.CalcNoOfSubstitutions(Rec))
                {
                    ApplicationArea = Suite;
                    Caption = 'Substitutions';
                    DrillDown = true;
                    ToolTip = 'Specifies other items that are set up to be traded instead of the item in case it is not available.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        ShowItemSub();
                        CurrPage.Update(true);
                        if (Reserve = Reserve::Always) and ("No." <> xRec."No.") then begin
                            AutoReserve();
                            CurrPage.Update(false);
                        end;
                    end;
                }
                field(SalesPrices; SalesInfoPaneMgt.CalcNoOfSalesPrices(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    DrillDown = true;
                    ToolTip = 'Specifies special sales prices that you grant when certain conditions are met, such as customer, quantity, or ending date. The price agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';

                    trigger OnDrillDown()
                    begin
                        PickPrice();
                        CurrPage.Update();
                    end;
                }
                field(SalesLineDiscounts; SalesInfoPaneMgt.CalcNoOfSalesLineDisc(Rec))
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Line Discounts';
                    DrillDown = true;
                    ToolTip = 'Specifies how many special discounts you grant for the sales line. Choose the value to see the sales line discounts.';

                    trigger OnDrillDown()
                    begin
                        PickDiscount();
                        CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        ClearSalesHeader();
    end;

    trigger OnAfterGetRecord()
    begin
        CalcFields("Reserved Quantity", "Attached Doc Count");
        SalesInfoPaneMgt.ResetItemNo();
    end;

    var
        SalesInfoPaneMgt: Codeunit "Sales Info-Pane Management";
        ItemAvailFormsMgt: Codeunit "Item Availability Forms Mgt";

    local procedure ShowNo(): Code[20]
    begin
        if Type <> Type::Item then
            exit('');
        exit("No.");
    end;
}

