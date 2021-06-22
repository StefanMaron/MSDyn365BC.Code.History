page 6052 "Service Contract Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;
    PageType = ListPart;
    SourceTable = "Service Contract Line";
    SourceTableView = WHERE("Contract Type" = FILTER(Contract));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Service Item No."; "Service Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service item that is subject to the service contract.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ServContractMgt: Codeunit ServContractManagement;
                    begin
                        ServContractMgt.LookupServItemNo(Rec);
                        if xRec.Get("Contract Type", "Contract No.", "Line No.") then;
                    end;
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of the service item that is subject to the contract.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Serial No."; "Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the service item that is subject to the contract.';

                    trigger OnAssistEdit()
                    begin
                        Clear(ItemLedgerEntry);
                        ItemLedgerEntry.SetRange("Item No.", "Item No.");
                        ItemLedgerEntry.SetRange("Variant Code", "Variant Code");
                        ItemLedgerEntry.SetRange("Serial No.", "Serial No.");
                        PAGE.Run(PAGE::"Item Ledger Entries", ItemLedgerEntry);
                    end;
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Service;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the number of the item linked to the service item in the service contract.';
                }
                field("Variant Code"; "Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Response Time (Hours)"; "Response Time (Hours)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the response time for the service item associated with the service contract.';
                }
                field("Line Cost"; "Line Cost")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the calculated cost of the service item line in the service contract or contract quote.';
                }
                field("Line Value"; "Line Value")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the value of the service item line in the contract or contract quote.';
                }
                field("Line Discount %"; "Line Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount percentage that is granted for the item on the line.';
                }
                field("Line Discount Amount"; "Line Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount amount that is granted for the item on the line.';
                    Visible = false;
                }
                field("Line Amount"; "Line Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the net amount, excluding any invoice discount amount, that must be paid for products on the line.';
                }
                field(Profit; Profit)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the profit, expressed as the difference between the Line Amount and Line Cost fields on the service contract line.';
                }
                field("Service Period"; "Service Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the period of time that must pass between each servicing of an item.';
                }
                field("Next Planned Service Date"; "Next Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the next planned service on the item included in the contract.';
                }
                field("Last Planned Service Date"; "Last Planned Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date of the last planned service on this item.';
                    Visible = false;
                }
                field("Last Preventive Maint. Date"; "Last Preventive Maint. Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the last time preventative service was performed on this item.';
                    Visible = false;
                }
                field("Last Service Date"; "Last Service Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the service item on the line was last serviced.';
                    Visible = false;
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the starting date of the service contract.';
                }
                field("Contract Expiration Date"; "Contract Expiration Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when an item should be removed from the contract.';
                }
                field("Credit Memo Date"; "Credit Memo Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when you can create a credit memo for the service item that needs to be removed from the service contract.';
                }
                field(Credited; Credited)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies if the service contract line has been credited.';
                    Visible = false;
                }
                field("New Line"; "New Line")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the service contract line is new or existing.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("&Comments")
                {
                    ApplicationArea = Comments;
                    Caption = '&Comments';
                    Image = ViewComments;
                    ToolTip = 'View or create a comment.';

                    trigger OnAction()
                    begin
                        ShowComments;
                    end;
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if "Contract Status" = "Contract Status"::Signed then begin
            ServContractLine.CopyFilters(Rec);
            CurrPage.SetSelectionFilter(ServContractLine);
            NoOfSelectedLines := ServContractLine.Count();
            if NoOfSelectedLines = 1 then
                CreateCreditfromContractLines.SetSelectionFilterNo(NoOfSelectedLines);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        SetupNewLine;
    end;

    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ServContractLine: Record "Service Contract Line";
        CreateCreditfromContractLines: Codeunit CreateCreditfromContractLines;
        NoOfSelectedLines: Integer;
}

