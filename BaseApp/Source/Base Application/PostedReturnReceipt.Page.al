page 6660 "Posted Return Receipt"
{
    Caption = 'Posted Return Receipt';
    InsertAllowed = false;
    PageType = Document;
    PromotedActionCategories = 'New,Process,Report,Print/Send,Receipt';
    RefreshOnActivate = true;
    SourceTable = "Return Receipt Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; "No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Sell-to Customer No."; "Sell-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer.';
                }
                field("Sell-to Contact No."; "Sell-to Contact No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact person at the customer''s main address.';
                }
                group("Sell-to")
                {
                    Caption = 'Sell-to';
                    field("Sell-to Customer Name"; "Sell-to Customer Name")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer.';
                    }
                    field("Sell-to Address"; "Sell-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the main address of the customer.';
                    }
                    field("Sell-to Address 2"; "Sell-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the address.';
                    }
                    group(Control19)
                    {
                        ShowCaption = false;
                        Visible = IsSellToCountyVisible;
                        field("Sell-to County"; "Sell-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'County';
                            Editable = false;
                        }
                    }
                    field("Sell-to Post Code"; "Sell-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the customer''s main address.';
                    }
                    field("Sell-to City"; "Sell-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the customer''s main address.';
                    }
                    field("Sell-to Country/Region Code"; "Sell-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Sell-to Contact"; "Sell-to Contact")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer''s main address.';
                    }
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; "Document Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Return Order No."; "Return Order No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the return order that will post a return receipt.';
                }
                field("External Document No."; "External Document No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies which salesperson is associated with the posted return receipt.';
                }
                field("Responsibility Center"; "Responsibility Center")
                {
                    ApplicationArea = Suite;
                    Editable = false;
                    ToolTip = 'Specifies the code of the responsibility center, such as a distribution hub, that is associated with the involved user, company, customer, or vendor.';
                }
                field("No. Printed"; "No. Printed")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies how many times the document has been printed.';
                }
            }
            part(ReturnRcptLines; "Posted Return Receipt Subform")
            {
                ApplicationArea = SalesReturnOrder;
                SubPageLink = "Document No." = FIELD("No.");
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                }
                field("Bill-to Contact No."; "Bill-to Contact No.")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies the number of the contact person at the customer''s billing address.';
                }
                group("Bill-to")
                {
                    Caption = 'Bill-to';
                    Visible = IsBillToCountyVisible;
                    field("Bill-to Name"; "Bill-to Name")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    }
                    field("Bill-to Address"; "Bill-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address of the customer to whom you sent the invoice.';
                    }
                    field("Bill-to Address 2"; "Bill-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional line of the address.';
                    }
                    group(Control29)
                    {
                        ShowCaption = false;
                        field("Bill-to County"; "Bill-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'County';
                            Editable = false;
                        }
                    }
                    field("Bill-to Post Code"; "Bill-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    }
                    field("Bill-to City"; "Bill-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address.';
                    }
                    field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Bill-to Contact"; "Bill-to Contact")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    }
                }
                field("Shortcut Dimension 1 Code"; "Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; "Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = false;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
            }
            group(Shipping)
            {
                Caption = 'Shipping';
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                }
                group("Ship-to")
                {
                    Caption = 'Ship-to';
                    Visible = IsShipToCountyVisible;
                    field("Ship-to Name"; "Ship-to Name")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Name';
                        Editable = false;
                        ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    }
                    field("Ship-to Address"; "Ship-to Address")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address';
                        Editable = false;
                        ToolTip = 'Specifies the address that the items are shipped to.';
                    }
                    field("Ship-to Address 2"; "Ship-to Address 2")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Address 2';
                        Editable = false;
                        ToolTip = 'Specifies an additional part of the ship-to address, in case it is a long address.';
                    }
                    group(Control37)
                    {
                        ShowCaption = false;
                        field("Ship-to County"; "Ship-to County")
                        {
                            ApplicationArea = SalesReturnOrder;
                            Caption = 'County';
                            Editable = false;
                        }
                    }
                    field("Ship-to Post Code"; "Ship-to Post Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Post Code';
                        Editable = false;
                        ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    }
                    field("Ship-to City"; "Ship-to City")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'City';
                        Editable = false;
                        ToolTip = 'Specifies the city of the address that the items are shipped to.';
                    }
                    field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Country/Region';
                        Editable = false;
                    }
                    field("Ship-to Contact"; "Ship-to Contact")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Contact';
                        Editable = false;
                        ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    }
                }
                field("Location Code"; "Location Code")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies a code for the location where you want the items to be placed when they are received.';
                }
                group("Shipment Method")
                {
                    Caption = 'Shipment Method';
                    field("Shipment Method Code"; "Shipment Method Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Code';
                        Editable = false;
                        ToolTip = 'Specifies the reason for the posted return.';
                    }
                    field("Shipping Agent Code"; "Shipping Agent Code")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Caption = 'Agent';
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies which shipping agent is used to transport the items on the sales document to the customer.';
                    }
                    field("Package Tracking No."; "Package Tracking No.")
                    {
                        ApplicationArea = SalesReturnOrder;
                        Editable = false;
                        Importance = Additional;
                        ToolTip = 'Specifies the shipping agent''s package number.';
                    }
                }
                field("Shipment Date"; "Shipment Date")
                {
                    ApplicationArea = SalesReturnOrder;
                    Editable = false;
                    Importance = Promoted;
                    ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
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
            group("&Return Rcpt.")
            {
                Caption = '&Return Rcpt.';
                Image = Receipt;
                action(Statistics)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    RunObject = Page "Return Receipt Statistics";
                    RunPageLink = "No." = FIELD("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    Promoted = true;
                    PromotedCategory = Category5;
                    RunObject = Page "Sales Comment Sheet";
                    RunPageLink = "Document Type" = CONST("Posted Return Receipt"),
                                  "No." = FIELD("No."),
                                  "Document Line No." = CONST(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Dimensions)
                {
                    AccessByPermission = TableData Dimension = R;
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    Promoted = true;
                    PromotedCategory = Category5;
                    PromotedIsBig = true;
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        ShowDimensions;
                    end;
                }
                action(Approvals)
                {
                    AccessByPermission = TableData "Posted Approval Entry" = R;
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Approvals';
                    Image = Approvals;
                    Promoted = true;
                    PromotedCategory = Category5;
                    ToolTip = 'View a list of the records that are waiting to be approved. For example, you can see who requested the record to be approved, when it was sent, and when it is due to be approved.';

                    trigger OnAction()
                    var
                        ApprovalsMgmt: Codeunit "Approvals Mgmt.";
                    begin
                        ApprovalsMgmt.ShowPostedApprovalEntries(RecordId);
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(DocumentLineTracking)
                {
                    ApplicationArea = SalesReturnOrder;
                    Caption = 'Document &Line Tracking';
                    Image = Navigate;
                    ToolTip = 'View related open, posted, or archived documents or document lines.';

                    trigger OnAction()
                    begin
                        CurrPage.ReturnRcptLines.PAGE.ShowDocumentLineTracking;
                    end;
                }
            }
        }
        area(processing)
        {
            action("&Print")
            {
                ApplicationArea = SalesReturnOrder;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Category4;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    ReturnRcptHeader := Rec;
                    OnBeforePrintRecords(Rec, ReturnRcptHeader);
                    CurrPage.SetSelectionFilter(ReturnRcptHeader);
                    ReturnRcptHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = SalesReturnOrder;
                Caption = '&Navigate';
                Image = Navigate;
                Promoted = true;
                PromotedCategory = Category5;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected posted sales document.';

                trigger OnAction()
                begin
                    Navigate;
                end;
            }
            action("Update Document")
            {
                ApplicationArea = SalesReturnOrder;
                Caption = 'Update Document';
                Image = Edit;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Add new information that is relevant to the document, such as information from the shipping agent. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedReturnReceiptUpdate: Page "Posted Return Receipt - Update";
                begin
                    PostedReturnReceiptUpdate.LookupMode := true;
                    PostedReturnReceiptUpdate.SetRec(Rec);
                    PostedReturnReceiptUpdate.RunModal;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetSecurityFilterOnRespCenter;

        ActivateFields;
    end;

    var
        ReturnRcptHeader: Record "Return Receipt Header";
        FormatAddress: Codeunit "Format Address";
        IsBillToCountyVisible: Boolean;
        IsSellToCountyVisible: Boolean;
        IsShipToCountyVisible: Boolean;

    local procedure ActivateFields()
    begin
        IsSellToCountyVisible := FormatAddress.UseCounty("Sell-to Country/Region Code");
        IsShipToCountyVisible := FormatAddress.UseCounty("Ship-to Country/Region Code");
        IsBillToCountyVisible := FormatAddress.UseCounty("Bill-to Country/Region Code");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintRecords(ReturnReceiptHeaderRec: Record "Return Receipt Header"; var ReturnReceiptHeaderToPrint: Record "Return Receipt Header")
    begin
    end;
}

