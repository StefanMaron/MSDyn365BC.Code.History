namespace Microsoft.Service.History;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.Attachment;
using Microsoft.Service.Comment;

page 5977 "Posted Service Invoices"
{
    ApplicationArea = Service;
    Caption = 'Posted Service Invoices';
    CardPageID = "Posted Service Invoice";
    Editable = false;
    PageType = List;
    SourceTable = "Service Invoice Header";
    SourceTableView = sorting("Posting Date")
                      order(descending);
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the related order.';
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer who owns the items on the invoice.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer on the service invoice.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a document number that refers to the customer''s numbering system.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency code for the amounts on the invoice.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total invoice amount excluding VAT.';
                }
                field("Amount Including VAT"; Rec."Amount Including VAT")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the total invoice amount including VAT.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the customer company.';
                    Visible = false;
                }
                field("Bill-to Customer No."; Rec."Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Name"; Rec."Bill-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Post Code"; Rec."Bill-to Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; Rec."Bill-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Contact"; Rec."Bill-to Contact")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    Visible = false;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; Rec."Ship-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; Rec."Ship-to Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; Rec."Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; Rec."Ship-to Contact")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the invoice was posted.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson associated with the invoice.';
                    Visible = false;
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, from which the service was shipped.';
                    Visible = true;
                }
                field("SII Status"; Rec."SII Status")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleText;
                    ToolTip = 'Specifies the document''s status with regard to tax declaration, the Immediate Information Supply requirement. ';
                    Visible = SIIStateVisible;

                    trigger OnDrillDown()
                    var
                        SIIDocUploadState: Record "SII Doc. Upload State";
                        SIIManagement: Codeunit "SII Management";
                    begin
                        SIIDocUploadState.SetRange("Document Source", SIIDocUploadState."Document Source"::"Customer Ledger");
                        SIIDocUploadState.SetRange("Document Type", SIIDocUploadState."Document Type"::Invoice);
                        SIIDocUploadState.SetRange("Document No.", Rec."No.");
                        SIIManagement.SIIStateDrilldown(SIIDocUploadState);
                    end;
                }
                field("Do Not Send To SII"; Rec."Do Not Send To SII")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the document must not be sent to SII.';
                }
                field("Sent to SII"; Rec."Sent to SII")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the document has been sent to the Immediate Information Supply system.';
                    Visible = SIIStateVisible;
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document Exchange Status"; Rec."Document Exchange Status")
                {
                    ApplicationArea = Service;
                    Editable = false;
                    StyleExpr = DocExchStatusStyle;
                    ToolTip = 'Specifies the status of the document if you are using a document exchange service to send it as an electronic document. The status values are reported by the document exchange service.';
                    Visible = DocExchStatusVisible;

                    trigger OnDrillDown()
                    var
                        DocExchServDocStatus: Codeunit "Doc. Exch. Serv.- Doc. Status";
                    begin
                        DocExchServDocStatus.DocExchStatusDrillDown(Rec);
                    end;
                }
            }
        }
        area(factboxes)
        {
            part("Attached Documents"; "Document Attachment Factbox")
            {
                ApplicationArea = Service;
                Caption = 'Attachments';
                SubPageLink = "Table ID" = const(Database::"Service Invoice Header"),
                              "No." = field("No.");
            }
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
            group("&Invoice")
            {
                Caption = '&Invoice';
                Image = Invoice;
                action(Statistics)
                {
                    ApplicationArea = Service;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Service Invoice Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = "Table Name" = const("Service Invoice Header"),
                                  "No." = field("No."),
                                  Type = const(General);
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
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
                    end;
                }
            }
        }
        area(processing)
        {
            action(SendCustom)
            {
                ApplicationArea = Service;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                begin
                    ServiceInvHeader := Rec;
                    CurrPage.SetSelectionFilter(ServiceInvHeader);
                    ServiceInvHeader.SendRecords();
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(ServiceInvHeader);
                    ServiceInvHeader.PrintRecords(true);
                end;
            }
            action(AttachAsPDF)
            {
                ApplicationArea = Service;
                Caption = 'Attach as PDF';
                Image = PrintAttachment;
                ToolTip = 'Create a PDF file and attach it to the document.';

                trigger OnAction()
                var
                    ServiceInvoiceHeader: Record "Service Invoice Header";
                begin
                    ServiceInvoiceHeader := Rec;
                    ServiceInvoiceHeader.SetRecFilter();
                    Rec.PrintToDocumentAttachment(ServiceInvoiceHeader);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
                Caption = 'Find entries...';
                Image = Navigate;
                ShortCutKey = 'Ctrl+Alt+Q';
                ToolTip = 'Find entries and documents that exist for the document number and posting date on the selected document. (Formerly this action was named Navigate.)';

                trigger OnAction()
                begin
                    Rec.Navigate();
                end;
            }
            action(ActivityLog)
            {
                ApplicationArea = Service;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                begin
                    Rec.ShowActivityLog();
                end;
            }
            action("Update Document")
            {
                ApplicationArea = Service;
                Caption = 'Update Document';
                Image = Edit;
                ToolTip = 'Add new information that is relevant to the document. You can only edit a few fields because the document has already been posted.';

                trigger OnAction()
                var
                    PostedServInvoiceUpdate: Page "Posted Serv. Invoice - Update";
                begin
                    PostedServInvoiceUpdate.LookupMode := true;
                    PostedServInvoiceUpdate.SetRec(Rec);
                    PostedServInvoiceUpdate.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                group(Category_CategoryPrint)
                {
                    ShowAs = SplitButton;

                    actionref("&Print_Promoted"; "&Print")
                    {
                    }
                    actionref(AttachAsPDF_Promoted; AttachAsPDF)
                    {
                    }
                }
                actionref(SendCustom_Promoted; SendCustom)
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("Update Document_Promoted"; "Update Document")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();
    end;

    trigger OnAfterGetRecord()
    var
        SIIManagement: Codeunit "SII Management";
    begin
        DocExchStatusStyle := Rec.GetDocExchStatusStyle();

        StyleText := SIIManagement.GetSIIStyle(Rec."SII Status".AsInteger());
    end;

    trigger OnOpenPage()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        SIISetup: Record "SII Setup";
    begin
        Rec.SetSecurityFilterOnRespCenter();

        ServiceInvoiceHeader.CopyFilters(Rec);
        ServiceInvoiceHeader.SetFilter("Document Exchange Status", '<>%1', Rec."Document Exchange Status"::"Not Sent");
        DocExchStatusVisible := not ServiceInvoiceHeader.IsEmpty();

        SIIStateVisible := SIISetup.IsEnabled();
    end;

    var
        ServiceInvHeader: Record "Service Invoice Header";
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
        StyleText: Text;
        SIIStateVisible: Boolean;
}

