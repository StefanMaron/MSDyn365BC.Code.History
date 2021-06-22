page 163 "Warranty Ledg. Entries Preview"
{
    Caption = 'Warranty Ledger Entries Preview';
    DataCaptionFields = "Service Order No.", "Service Item No. (Serviced)", "Service Contract No.";
    Editable = false;
    PageType = List;
    SourceTable = "Warranty Ledger Entry";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the document number of this entry.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the posting date on the service line linked to this entry.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer on the service order linked to this entry.';
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Item No. (Serviced)"; "Item No. (Serviced)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the serviced item linked to this entry.';
                }
                field("Serial No. (Serviced)"; "Serial No. (Serviced)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the serviced item linked to this entry.';
                }
                field("Service Item Group (Serviced)"; "Service Item Group (Serviced)")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the service item group code of the serviced item linked to this entry.';
                }
                field("Service Order No."; "Service Order No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service order linked to this entry.';
                }
                field("Service Contract No."; "Service Contract No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the service contract linked to this entry.';
                }
                field("Fault Reason Code"; "Fault Reason Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault reason code of the service line linked to this entry.';
                }
                field("Fault Code"; "Fault Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the fault code of the service line linked to this entry.';
                }
                field("Symptom Code"; "Symptom Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the symptom code of the service line linked to this entry.';
                }
                field("Resolution Code"; "Resolution Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the resolution code of the service line linked to this entry.';
                }
                field(Type; Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of the service line linked to this entry.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Quantity; Quantity)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of item units, resource hours, or cost of the service line linked to this entry.';
                }
                field("Work Type Code"; "Work Type Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the work type code of the service line linked to this entry.';
                }
                field("Unit of Measure Code"; "Unit of Measure Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Amount; Amount)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the warranty discount amount of the service line linked to this entry.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the description of the item on this line.';
                }
                field("Global Dimension 1 Code"; "Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; "Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field(Open; Open)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies that the warranty ledger entry is open.';
                }
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the vendor number of the serviced item linked to this entry.';
                }
                field("Vendor Item No."; "Vendor Item No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
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

