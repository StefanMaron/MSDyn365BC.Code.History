page 780 "Certificates of Supply"
{
    ApplicationArea = Basic, Suite, Service;
    Caption = 'Certificates of Supply';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Certificate of Supply";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Document Type"; "Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the posted document to which the certificate of supply applies.';
                }
                field("Document No."; "Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the document number of the posted shipment document associated with the certificate of supply.';
                }
                field(Status; Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status for documents where you must receive a signed certificate of supply from the customer.';
                }
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Receipt Date"; "Receipt Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the receipt date of the signed certificate of supply.';
                }
                field(Printed; Printed)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies whether the certificate of supply has been printed and sent to the customer.';
                }
                field("Customer/Vendor Name"; "Customer/Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the customer or vendor.';
                }
                field("Shipment Date"; "Shipment/Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date that the posted shipment was shipped or posted.';
                }
                field("Shipment Country"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                }
                field("Customer/Vendor No."; "Customer/Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the customer or vendor.';
                }
                field("Shipment Method"; "Shipment Method Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Vehicle Registration No."; "Vehicle Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vehicle registration number associated with the shipment.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PrintCertificateofSupply)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print Certificate of Supply';
                Image = PrintReport;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Print the certificate of supply that you must send to your customer for signature as confirmation of receipt.';

                trigger OnAction()
                var
                    CertificateOfSupply: Record "Certificate of Supply";
                begin
                    if not IsEmpty then begin
                        CertificateOfSupply.Copy(Rec);
                        CertificateOfSupply.SetRange("Document Type", "Document Type");
                        CertificateOfSupply.SetRange("Document No.", "Document No.");
                    end;
                    CertificateOfSupply.Print;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if GetFilters = '' then
            SetFilter(Status, '<>%1', Status::"Not Applicable")
        else
            InitRecord("Document Type", "Document No.")
    end;
}

