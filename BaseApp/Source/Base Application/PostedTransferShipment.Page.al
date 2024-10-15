page 5743 "Posted Transfer Shipment"
{
    Caption = 'Posted Transfer Shipment';
    InsertAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Shipment';
    RefreshOnActivate = true;
    SourceTable = "Transfer Shipment Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Transfer-from Code"; "Transfer-from Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that items are transferred from.';
                }
                field("Transfer-to Code"; "Transfer-to Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code of the location that the items are transferred to.';
                }
                field("Direct Transfer"; "Direct Transfer")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies that the transfer does not use an in-transit location.';
                }
                field("In-Transit Code"; "In-Transit Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the in-transit code for the transfer order, such as a shipping agent.';
                }
                field("Transfer Order No."; "Transfer Order No.")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    Lookup = false;
                    ToolTip = 'Specifies the number of the related transfer order.';
                }
                field("Transfer Order Date"; "Transfer Order Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the date when the transfer order was created.';
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the posting date for this document.';
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            part(TransferShipmentLines; "Posted Transfer Shpt. Subform")
            {
                ApplicationArea = Location;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Shipment)
            {
                Caption = 'Shipment';
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
                }
                field("Shipment Method Code"; "Shipment Method Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the delivery conditions of the related shipment, such as free on board (FOB).';
                }
                field("Shipping Agent Code"; "Shipping Agent Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    ToolTip = 'Specifies the code for the shipping agent who is transporting the items.';
                }
                field("Shipping Agent Service Code"; "Shipping Agent Service Code")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the code for the service, such as a one-day delivery, that is offered by the shipping agent.';
                }
                field("Receipt Date"; "Receipt Date")
                {
                    ApplicationArea = Location;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the receipt date of the transfer order.';
                }
            }
            group("Transfer-from")
            {
                Caption = 'Transfer-from';
                field("Transfer-from Name"; "Transfer-from Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Name 2"; "Transfer-from Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the sender at the location that the items are transferred from.';
                }
                field("Transfer-from Address"; "Transfer-from Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the address of the location that the items are transferred from.';
                }
                field("Transfer-from Address 2"; "Transfer-from Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the address of the location that items are transferred from.';
                }
                field("Transfer-from City"; "Transfer-from City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the location that the items are transferred from.';
                }
                group(Control13)
                {
                    ShowCaption = false;
                    Visible = IsFromCountyVisible;
                    field("Transfer-from County"; "Transfer-from County")
                    {
                        ApplicationArea = Location;
                        Caption = 'County';
                        Editable = false;
                        Importance = Additional;
                    }
                }
                field("Transfer-from Post Code"; "Transfer-from Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the postal code of the location that the items are transferred from.';
                }
                field("Trsf.-from Country/Region Code"; "Trsf.-from Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-from Contact"; "Transfer-from Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that the items are transferred from.';
                }
            }
            group("Transfer-to")
            {
                Caption = 'Transfer-to';
                field("Transfer-to Name"; "Transfer-to Name")
                {
                    ApplicationArea = Location;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Name 2"; "Transfer-to Name 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Name 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the name of the recipient at the location that the items are transferred to.';
                }
                field("Transfer-to Address"; "Transfer-to Address")
                {
                    ApplicationArea = Location;
                    Caption = 'Address';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the address of the location that the items are transferred to.';
                }
                field("Transfer-to Address 2"; "Transfer-to Address 2")
                {
                    ApplicationArea = Location;
                    Caption = 'Address 2';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies an additional part of the address of the location that items are transferred to.';
                }
                field("Transfer-to City"; "Transfer-to City")
                {
                    ApplicationArea = Location;
                    Caption = 'City';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the city of the location that items are transferred to.';
                }
                group(Control21)
                {
                    ShowCaption = false;
                    Visible = IsToCountyVisible;
                    field("Transfer-to County"; "Transfer-to County")
                    {
                        ApplicationArea = Location;
                        Caption = 'County';
                        Editable = false;
                        Importance = Additional;
                    }
                }
                field("Transfer-to Post Code"; "Transfer-to Post Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Post Code';
                    Editable = false;
                    Importance = Additional;
                }
                field("Trsf.-to Country/Region Code"; "Trsf.-to Country/Region Code")
                {
                    ApplicationArea = Location;
                    Caption = 'Country/Region';
                    Editable = false;
                    Importance = Additional;
                }
                field("Transfer-to Contact"; "Transfer-to Contact")
                {
                    ApplicationArea = Location;
                    Caption = 'Contact';
                    Editable = false;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the contact person at the location that items are transferred to.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Transaction Type"; "Transaction Type")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the type of transaction that the document represents, for the purpose of reporting to INTRASTAT.';
                }
                field("Transaction Specification"; "Transaction Specification")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    ToolTip = 'Specifies a specification of the document''s transaction, for the purpose of reporting to INTRASTAT.';
                }
                field("Transport Method"; "Transport Method")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the transport method, for the purpose of reporting to INTRASTAT.';
                }
                field("Area"; Area)
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    ToolTip = 'Specifies the area of the customer or vendor, for the purpose of reporting to INTRASTAT.';
                }
                field("Entry/Exit Point"; "Entry/Exit Point")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    ToolTip = 'Specifies the code of either the port of entry at which the items passed into your country/region, or the port of exit.';
                }
                field("Partner VAT ID"; Rec."Partner VAT ID")
                {
                    ApplicationArea = BasicEU;
                    Editable = false;
                    ToolTip = 'Specifies the counter party''s VAT number.';
                }
            }
            group(ElectronicDocument)
            {
                Caption = 'Electronic Document';
                field("CFDI Export Code"; "CFDI Export Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies a code to indicate if the document is used for exports to other countries.';
                }
                field("Transport Operators"; "Transport Operators")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the operator of the vehicle that transports the goods or merchandise.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Transit-from Date/Time"; "Transit-from Date/Time")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the estimated date and time at which the goods or merchandise leave the start address.';
                }
                field("Transit Hours"; "Transit Hours")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the estimated time in hours that it will take to transit from the start address to the temporary or final destination.';
                }
                field("Transit Distance"; "Transit Distance")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the distance travelled in kilometers from the start address to the temporary or final destination as a combination of the distances that are travelled by the different means of transport that move the goods or merchandise.';
                }
                field("Vehicle Code"; "Vehicle Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the vehicle that transports the goods or merchandise.';
                }
                field("Trailer 1"; "Trailer 1")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the trailer or semi-trailer that is used with the vehicle for the transfer of goods or merchandise.';
                }
                field("Trailer 2"; "Trailer 2")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the second trailer or semi-trailer that is used with the vehicle for the transfer of goods or merchandise.';
                }
                field(Control1310010; "Foreign Trade")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies whether the goods or merchandise that are transported enter or leave the national territory.';
                }
                field("Insurer Name"; "Insurer Name")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the name of the insurer that covers the risks of the motor transport used for the transfer of goods or merchandise.';
                }
                field("Insurer Policy Number"; "Insurer Policy Number")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the policy number assigned by the insurer, which covers the risks of the motor transport used for the transfer of goods or merchandise.';
                }
                field("Medical Insurer Name"; "Medical Insurer Name")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the insurer that covers potential damage to the environment if the transport includes materials, residues or remnants, or hazardous waste.';
                }
                field("Medical Ins. Policy Number"; "Medical Ins. Policy Number")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the insurance policy number if the transport includes materials, residues or remnants, or hazardous waste.';
                }
                field("SAT Weight Unit Of Measure"; "SAT Weight Unit Of Measure")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the unit of measurement of the weight of the goods and / or merchandise that are moved in this transport.';
                }
                field("Electronic Document Status"; "Electronic Document Status")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; "Date/Time Stamped")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                }
                field("Date/Time Canceled"; "Date/Time Canceled")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                }
                field("Error Code"; "Error Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("Error Description"; "Error Description")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                }
                field("PAC Web Service Name"; "PAC Web Service Name")
                {
                    ApplicationArea = Location, BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the name of the authorized service provider, PAC, which has processed the electronic document.';
                }
                field("Fiscal Invoice Number PAC"; "Fiscal Invoice Number PAC")
                {
                    ApplicationArea = Location, BasicMX;
                    Importance = Additional;
                    ToolTip = 'Specifies the official invoice number for the electronic document.';
                }
                field("CFDI Cancellation Reason Code"; "CFDI Cancellation Reason Code")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the reason for the cancellation as a code.';
                }
                field("Substitution Document No."; "Substitution Document No.")
                {
                    ApplicationArea = Location, BasicMX;
                    ToolTip = 'Specifies the document number that replaces the canceled one. It is required when the cancellation reason is 01.';
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
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Shipment")
            {
                Caption = '&Shipment';
                Image = Shipment;
                action(Statistics)
                {
                    ApplicationArea = Location;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    RunObject = Page "Transfer Shipment Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information about the transfer order, such as the quantity and total weight transferred.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Inventory Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Transfer Shipment"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category4;
                    PromotedOnly = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions();
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = Location;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                PromotedOnly = true;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    TransShptHeader: Record "Transfer Shipment Header";
                begin
                    CurrPage.SetSelectionFilter(TransShptHeader);
                    TransShptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Location;
                Caption = 'Find entries...';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Process;
                ShortCutKey = 'Shift+Ctrl+I';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic invoice attached as an XML file.';

                    trigger OnAction()
                    begin
                        RequestStampEDocument();
                    end;
                }
                action("Export E-Document as &XML")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted sales invoice as an electronic invoice, and XML file, and save it to a specified location.';

                    trigger OnAction()
                    begin
                        ExportEDocument();
                    end;
                }
                action("&Cancel")
                {
                    ApplicationArea = BasicMX;
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic sales invoice.';

                    trigger OnAction()
                    begin
                        CancelEDocument();
                    end;
                }
                action("Print Carta Porte Document")
                {
                    ApplicationArea = BasicMX;
                    Caption = 'Print Carta Porte Document';
                    Image = PrintForm;
                    ToolTip = 'Prepare to print the Carta Porte document so that it can be shown upon request from inspectors or other authorities.';

                    trigger OnAction()
                    var
                        ElectronicCartaPorteMX: Report "Electronic Carta Porte MX";
                    begin
                        ElectronicCartaPorteMX.SetRecord(Rec);
                        ElectronicCartaPorteMX.Run();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsFromCountyVisible := FormatAddress.UseCounty("Trsf.-from Country/Region Code");
        IsToCountyVisible := FormatAddress.UseCounty("Trsf.-to Country/Region Code");
    end;

    var
        FormatAddress: Codeunit "Format Address";
        IsFromCountyVisible: Boolean;
        IsToCountyVisible: Boolean;
}

