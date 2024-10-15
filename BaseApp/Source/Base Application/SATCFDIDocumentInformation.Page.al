page 27015 "SAT CFDI Document Information"
{
    Caption = 'SAT CFDI Document Information';
    Editable = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Electronic Document';
    SourceTable = "CFDI Documents";

    layout
    {
        area(content)
        {
            group(General)
            {
                field("No."; "No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the CFDI document. ';
                }
            }
            group("Electronic Document")
            {
                field(Prepayment; Prepayment)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the CFDI documents involves a prepayment.';
                }
                field(Reversal; Reversal)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the CFDI documents involves a payment reversal.';
                }
                field("Electronic Document Status"; "Electronic Document Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the related electronic document.';
                }
                field("Date/Time Stamped"; "Date/Time Stamped")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the document was stamped.';
                }
                field("Date/Time Sent"; "Date/Time Sent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the document was sent.';
                }
                field("Date/Time Canceled"; "Date/Time Canceled")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the document was canceled.';
                }
                field("Error Code"; "Error Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies an error related to the related electronic document.';
                }
                field("Error Description"; "Error Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the error.';
                }
                field("PAC Web Service Name"; "PAC Web Service Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the web service.';
                }
                field("Fiscal Invoice Number PAC"; "Fiscal Invoice Number PAC")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the official invoice number for the related electronic document. When you generate an electronic document, Business Central sends it to a an authorized service provider, PAC, for processing. When the PAC returns the electronic document with the digital stamp, the electronic document includes a fiscal invoice number that uniquely identifies the document.';
                }
                field("No. of E-Documents Sent"; "No. of E-Documents Sent")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many electronic documents have been sent.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic invoice attached as an XML file.';

                    trigger OnAction()
                    begin
                        SendEDocument;
                    end;
                }
                action("Export E-Document as &XML")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    Promoted = true;
                    PromotedCategory = Category4;
                    ToolTip = 'Export the posted sales credit memo as an electronic credit memo, an XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        ExportEDocument;
                    end;
                }
            }
        }
    }
}

