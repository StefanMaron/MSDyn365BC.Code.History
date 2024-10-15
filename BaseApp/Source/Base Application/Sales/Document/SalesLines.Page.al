namespace Microsoft.Sales.Document;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.AllocationAccount.Sales;
using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Utilities;

page 516 "Sales Lines"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Sales Lines';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Sales Line";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document that you are about to create.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number.';
                }
                field("Sell-to Customer No."; Rec."Sell-to Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number.';
                    Visible = false;
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of entity that will be posted for this sales line, such as Item, Resource, or G/L Account. The type that you enter in this field determines what you can select in the No. field.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the entry of the product to be sold. To add a non-transactional text line, fill in the Description field only.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies information in addition to the description.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the inventory location from which the items sold should be picked and where the inventory decrease is registered.';
                    Visible = true;
                }
                field(Reserve; Rec.Reserve)
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies whether a reservation can be made for items on this line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units are being sold.';
                }
                field("Qty. to Ship"; Rec."Qty. to Ship")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the quantity of items that remain to be shipped.';
                    Visible = false;
                }
                field("Reserved Qty. (Base)"; Rec."Reserved Qty. (Base)")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the value in the Reserved Quantity field, expressed in the base unit of measure.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Line Amount"; Rec."Line Amount")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field("Allocation Account No."; Rec."Selected Alloc. Account No.")
                {
                    ApplicationArea = All;
                    Caption = 'Allocation Account No.';
                    ToolTip = 'Specifies the allocation account number that will be used to distribute the amounts during the posting process.';
                    Visible = UseAllocationAccountNumber;
                    trigger OnValidate()
                    var
                        SalesAllocAccMgt: Codeunit "Sales Alloc. Acc. Mgt.";
                    begin
                        SalesAllocAccMgt.VerifySelectedAllocationAccountNo(Rec);
                    end;
                }
                field("Job No."; Rec."Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related project. If you fill in this field and the Project Task No. field, then a project ledger entry will be posted together with the sales line.';
                    Visible = false;
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to when the sale is related to a project.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    ApplicationArea = Dimensions;
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;
                }
                field("Shipment Date"; Rec."Shipment Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Outstanding Quantity"; Rec."Outstanding Quantity")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many units on the order line have not yet been shipped.';
                }
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
                action("Show Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Document';
                    Image = View;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';

                    trigger OnAction()
                    var
                        PageManagement: Codeunit "Page Management";
                    begin
                        SalesHeader.Get(Rec."Document Type", Rec."Document No.");
                        PageManagement.PageRun(SalesHeader);
                    end;
                }
                action("Reservation Entries")
                {
                    AccessByPermission = TableData Item = R;
                    ApplicationArea = Reservation;
                    Caption = 'Reservation Entries';
                    Image = ReservationLedger;
                    ToolTip = 'View the entries for every reservation that is made, either manually or automatically.';

                    trigger OnAction()
                    begin
                        Rec.ShowReservationEntries(true);
                    end;
                }
                action("Item &Tracking Lines")
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
                action("Detach Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detach Lines';
                    Image = CancelAllLines;
                    Visible = DetachLinesVisible;
                    ToolTip = 'Detach the selected non-inventory product lines from the inventory item line.';

                    trigger OnAction()
                    var
                        SalesLine: Record "Sales Line";
                    begin
                        CurrPage.SetSelectionFilter(SalesLine);
                        SalesLine.ModifyAll("Attached to Line No.", 0);
                    end;
                }
                action(RedistributeAccAllocations)
                {
                    ApplicationArea = All;
                    Caption = 'Redistribute Account Allocations';
                    Image = EditList;
#pragma warning disable AA0219
                    ToolTip = 'Use this action to redistribute the account allocations for this line.';
#pragma warning restore AA0219

                    trigger OnAction()
                    var
                        AllocAccManualOverride: Page "Redistribute Acc. Allocations";
                    begin
                        if ((Rec."Type" <> Rec."Type"::"Allocation Account") and (Rec."Selected Alloc. Account No." = '')) then
                            Error(ActionOnlyAllowedForAllocationAccountsErr);

                        AllocAccManualOverride.SetParentSystemId(Rec.SystemId);
                        AllocAccManualOverride.SetParentTableId(Database::"Sales Line");
                        AllocAccManualOverride.RunModal();
                    end;
                }
                action(ReplaceAllocationAccountWithLines)
                {
                    ApplicationArea = All;
                    Caption = 'Generate lines from Allocation Account Line';
                    Image = CreateLinesFromJob;
#pragma warning disable AA0219
                    ToolTip = 'Use this action to replace the Allocation Account line with the actual lines that would be generated from the line itself.';
#pragma warning restore AA0219

                    trigger OnAction()
                    var
                        SalesAllocAccMgt: Codeunit "Sales Alloc. Acc. Mgt.";
                    begin
                        if ((Rec."Type" <> Rec."Type"::"Allocation Account") and (Rec."Selected Alloc. Account No." = '')) then
                            Error(ActionOnlyAllowedForAllocationAccountsErr);

                        SalesAllocAccMgt.CreateLinesFromAllocationAccountLine(Rec);
                        Rec.Delete();
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

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
                actionref("Item &Tracking Lines_Promoted"; "Item &Tracking Lines")
                {
                }
                actionref("Reservation Entries_Promoted"; "Reservation Entries")
                {
                }
                actionref("Detach Lines_Promoted"; "Detach Lines")
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        AllocationAccountMgt: Codeunit "Allocation Account Mgt.";
    begin
        UseAllocationAccountNumber := AllocationAccountMgt.UseAllocationAccountNoField();
        DetachLinesVisible := Rec.GetFilter("Attached to Line No.") <> '';
    end;

    var
        SalesHeader: Record "Sales Header";
        DetachLinesVisible: Boolean;
        UseAllocationAccountNumber: Boolean;
        ActionOnlyAllowedForAllocationAccountsErr: Label 'This action is only available for lines that have Allocation Account set as Type.';

    protected var
        ShortcutDimCode: array[8] of Code[20];
}

