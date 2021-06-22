page 168 "Service Ledger Entries Preview"
{
    Caption = 'Service Ledger Entries Preview';
    DataCaptionFields = "Service Contract No.", "Service Item No. (Serviced)", "Service Order No.";
    Editable = false;
    PageType = List;
    SourceTable = "Service Ledger Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when this entry was posted.';
                }
                field("Entry Type"; "Entry Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type for this entry.';
                }
                field("Service Order Type"; "Service Order Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service order if this entry was created for a service order.';
                    Visible = false;
                }
                field("Service Contract No."; "Service Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract, if this entry is linked to a service contract.';
                }
                field("Service Order No."; "Service Order No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order, if this entry was created for a service order.';
                }
                field("Job No."; "Job No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job.';
                    Visible = false;
                }
                field("Job Task No."; "Job Task No.")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the number of the related job task.';
                    Visible = false;
                }
                field("Job Line Type"; "Job Line Type")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies the journal line type that is created in the Job Planning Line table and linked to this job ledger entry.';
                    Visible = false;
                }
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the document type of the service ledger entry.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the document from which this entry was created.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer related to this entry.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Service Item No. (Serviced)"; "Service Item No. (Serviced)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the serviced item associated with this entry.';
                }
                field("Item No. (Serviced)"; "Item No. (Serviced)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the serviced item associated with this entry.';
                }
                field("Serial No. (Serviced)"; "Serial No. (Serviced)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the serviced item associated with this entry.';
                }
                field("Contract Invoice Period"; "Contract Invoice Period")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the invoice period of that contract, if this entry originates from a service contract.';
                    Visible = false;
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Contract Group Code"; "Contract Group Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the contract group code of the service contract to which this entry is associated.';
                    Visible = false;
                }
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of origin of this entry.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Cost Amount"; "Cost Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total cost on the line by multiplying the unit cost by the quantity.';
                }
                field("Discount Amount"; "Discount Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total discount amount on this entry.';
                }
                field("Unit Cost"; "Unit Cost")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of units in this entry.';
                }
                field("Charged Qty."; "Charged Qty.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of units in this entry that should be invoiced.';
                }
                field("Unit Price"; "Unit Price")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
                }
                field("Discount %"; "Discount %")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the discount percentage of this entry.';
                }
                field("Contract Disc. Amount"; "Contract Disc. Amount")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total contract discount amount of this entry.';
                    Visible = false;
                }
                field("Amount (LCY)"; "Amount (LCY)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount of the entry in LCY.';
                }
                field("Moved from Prepaid Acc."; "Moved from Prepaid Acc.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that this entry is not a prepaid entry from a service contract.';
                }
                field("Serv. Contract Acc. Gr. Code"; "Serv. Contract Acc. Gr. Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service contract account group code the service contract is associated with, if this entry is included in a service contract.';
                }
                field("Fault Reason Code"; "Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault reason code for this entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a description of the resource, item, cost, standard text, general ledger account, or service contract associated with this entry.';
                }
                field("Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                }
                field("Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the code for the location associated with this entry.';
                    Visible = false;
                }
                field("Bin Code"; "Bin Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the bin where the items are picked or put away.';
                    Visible = false;
                }
                field(Prepaid; Prepaid)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies whether the service contract or contract-related service order was prepaid.';
                    Visible = false;
                }
                field(Open; Open)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies contract-related service ledger entries.';
                }
                field("User ID"; "User ID")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';

                    trigger OnDrillDown()
                    var
                        UserMgt: Codeunit "User Management";
                    begin
                        UserMgt.DisplayUserInformation("User ID");
                    end;
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the amount on this entry.';
                }
                field("Dimension Set ID"; "Dimension Set ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Entry")
            {
                Caption = '&Entry';
                Image = Entry;
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(SetDimensionFilter)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Set Dimension Filter';
                    Ellipsis = true;
                    Image = "Filter";
                    ToolTip = 'Limit the entries according to the dimension filters that you specify. NOTE: If you use a high number of dimension combinations, this function may not work and can result in a message that the SQL server only supports a maximum of 2100 parameters.';

                    trigger OnAction()
                    begin
                        SetFilter("Dimension Set ID", DimensionSetIDFilter.LookupFilter);
                    end;
                }
            }
        }
    }

    var
        DimensionSetIDFilter: Page "Dimension Set ID Filter";
}

