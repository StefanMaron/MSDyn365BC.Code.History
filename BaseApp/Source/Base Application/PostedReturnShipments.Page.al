page 6652 "Posted Return Shipments"
{
    ApplicationArea = PurchReturnOrder;
    Caption = 'Posted Purchase Return Shipments';
    CardPageID = "Posted Return Shipment";
    Editable = false;
    PageType = List;
    SourceTable = "Return Shipment Header";
    SourceTableView = SORTING("Posting Date")
                      ORDER(Descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; "No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Buy-from Vendor No."; "Buy-from Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Order Address Code"; "Order Address Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the order address of the related customer.';
                    Visible = false;
                }
                field("Buy-from Vendor Name"; "Buy-from Vendor Name")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the name of the vendor who delivered the items.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the currency that is used on the entry.';
                    Visible = false;
                }
                field("Buy-from Post Code"; "Buy-from Post Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the post code of the vendor who delivered the items.';
                    Visible = false;
                }
                field("Buy-from Country/Region Code"; "Buy-from Country/Region Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the city of the vendor who delivered the items.';
                    Visible = false;
                }
                field("Buy-from Contact"; "Buy-from Contact")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the name of the contact person at the vendor who delivered the items.';
                    Visible = false;
                }
                field("Pay-to Vendor No."; "Pay-to Vendor No.")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the number of the vendor that you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Name"; "Pay-to Name")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the name of the customer who you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Post Code"; "Pay-to Post Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the post code of the customer that you received the invoice from.';
                    Visible = false;
                }
                field("Pay-to Country/Region Code"; "Pay-to Country/Region Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the country/region code of the address.';
                    Visible = false;
                }
                field("Pay-to Contact"; "Pay-to Contact")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the name of the person to contact about an invoice from this customer.';
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the entry''s posting date.';
                    Visible = false;
                }
                field("Purchaser Code"; "Purchaser Code")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
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
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the location from where inventory items to the customer on the sales document are to be shipped by default.';
                    Visible = true;
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Applies-to Doc. Type"; "Applies-to Doc. Type")
                {
                    ApplicationArea = PurchReturnOrder;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Return Shpt.")
            {
                Caption = '&Return Shpt.';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    RunObject = Page "Return Shipment Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Return Shipment"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
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
                action(CertificateOfSupplyDetails)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Certificate of Supply Details';
                    Image = Certificate;
                    RunObject = Page "Certificates of Supply";
                    RunPageLink = "Document Type" = FILTER("Return Shipment"),
                                  "Document No." = FIELD("No.");
                    ToolTip = 'View the certificate of supply that you must send to your customer for signature as confirmation of receipt. You must print a certificate of supply if the shipment uses a combination of VAT business posting group and VAT product posting group that have been marked to require a certificate of supply in the VAT Posting Setup window.';
                }
                action(PrintCertificateofSupply)
                {
                    ApplicationArea = PurchReturnOrder;
                    Caption = 'Print Certificate of Supply';
                    Image = PrintReport;
                    ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                    trigger OnAction()
                    var
                        CertificateOfSupply: Record "Certificate of Supply";
                    begin
                        CertificateOfSupply.SetRange("Document Type", CertificateOfSupply."Document Type"::"Return Shipment");
                        CertificateOfSupply.SetRange("Document No.", "No.");
                        CertificateOfSupply.Print;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = PurchReturnOrder;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    ReturnShptHeader := Rec;
                    OnBeforePrintRecords(Rec, ReturnShptHeader);
                    CurrPage.SetSelectionFilter(ReturnShptHeader);
                    ReturnShptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = PurchReturnOrder;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
            action("Update Document")
            {
                ApplicationArea = PurchReturnOrder;
                Caption = 'Update Document';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Add new information that is relevant to the document, such as the country or region. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedReturnShptUpdate: Page "Posted Return Shpt. - Update";
                begin
                    PostedReturnShptUpdate.LookupMode := true;
                    PostedReturnShptUpdate.SetRec(Rec);
                    PostedReturnShptUpdate.RunModal;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetSecurityFilterOnRespCenter;
    end;

    var
        ReturnShptHeader: Record "Return Shipment Header";

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(ReturnShipmentHeaderRec: Record "Return Shipment Header"; var ReturnShipmentHeaderToPrint: Record "Return Shipment Header")
    begin
    end;
}

