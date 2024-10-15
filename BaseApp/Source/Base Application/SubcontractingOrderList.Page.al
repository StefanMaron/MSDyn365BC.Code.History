page 35490 "Subcontracting Order List"
{
    ApplicationArea = Manufacturing;
    Caption = 'Subcontracting Orders';
    CardPageID = "Subcontracting Order";
    DataCaptionFields = "Document Type";
    Editable = false;
    PageType = List;
    SourceTable = "Purchase Header";
    SourceTableView = WHERE("Subcontracting Order" = CONST(true));
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the document number.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the vendor.';
                }
                field("Order Address Code"; "Order Address Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the address.';
                    Visible = false;
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company name of the vendor.';
                }
                field("Vendor Authorization No."; "Vendor Authorization No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the authoritization number of the vendor.';
                }
                field("Buy-from Post Code"; "Buy-from Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code of the vendor.';
                    Visible = false;
                }
                field("Buy-from Country/Region Code"; "Buy-from Country/Region Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the country or region of the vendor.';
                    Visible = false;
                }
                field("Buy-from Contact"; "Buy-from Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies your contact person.';
                    Visible = false;
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the vendor.';
                    Visible = false;
                }
                field("Pay-to Name"; "Pay-to Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company name of the vendor.';
                    Visible = false;
                }
                field("Pay-to Post Code"; "Pay-to Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code of the vendor.';
                    Visible = false;
                }
                field("Pay-to Country/Region Code"; "Pay-to Country/Region Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the country or region of the vendor.';
                    Visible = false;
                }
                field("Pay-to Contact"; "Pay-to Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies your contact person.';
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the company.';
                    Visible = false;
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the name of the company.';
                    Visible = false;
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the post code.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the country or region.';
                    Visible = false;
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the contact person.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the posting date of the document.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DimMgt.LookupDimValueCodeNoUpdate(1);
                    end;
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        DimMgt.LookupDimValueCodeNoUpdate(2);
                    end;
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the warehouse location.';
                    Visible = true;
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the purchaser.';
                    Visible = false;
                }
                field("Assigned User ID"; "Assigned User ID")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the user that the document is assigned to.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the currency that is associated with the document.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
    }

    var
        DimMgt: Codeunit DimensionManagement;
}

