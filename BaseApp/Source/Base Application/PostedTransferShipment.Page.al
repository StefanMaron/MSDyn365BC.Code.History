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
                        ShowDimensions;
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

