page 5971 "Posted Service Credit Memos"
{
    ApplicationArea = Service;
    Caption = 'Posted Service Credit Memos';
    CardPageID = "Posted Service Credit Memo";
    Editable = false;
    PageType = List;
    SourceTable = "Service Cr.Memo Header";
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
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field("Customer No."; "Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer associated with the credit memo.';
                }
                field(Name; Name)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer to whom you shipped the service on the credit memo.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the currency code for the amounts on the credit memo.';
                }
                field("Post Code"; "Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; "Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Contact Name"; "Contact Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the customer company.';
                    Visible = false;
                }
                field("Bill-to Customer No."; "Bill-to Customer No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Name"; "Bill-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer that you send or sent the invoice or credit memo to.';
                    Visible = false;
                }
                field("Bill-to Post Code"; "Bill-to Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Country/Region Code"; "Bill-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the customer''s billing address.';
                    Visible = false;
                }
                field("Bill-to Contact"; "Bill-to Contact")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the customer''s billing address.';
                    Visible = false;
                }
                field("Ship-to Code"; "Ship-to Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies a code for an alternate shipment address if you want to ship to another address than the one that has been entered automatically. This field is also used in case of drop shipment.';
                    Visible = false;
                }
                field("Ship-to Name"; "Ship-to Name")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the customer at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Post Code"; "Ship-to Post Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the postal code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Country/Region Code"; "Ship-to Country/Region Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the country/region code of the address that the items are shipped to.';
                    Visible = false;
                }
                field("Ship-to Contact"; "Ship-to Contact")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the name of the contact person at the address that the items are shipped to.';
                    Visible = false;
                }
                field("Posting Date"; "Posting Date")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the date when the credit memo was posted.';
                    Visible = false;
                }
                field("Salesperson Code"; "Salesperson Code")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the code of the salesperson associated with the credit memo.';
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
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location, such as warehouse or distribution center, where the credit memo was registered.';
                    Visible = true;
                }
                field("Electronic Document Status"; "Electronic Document Status")
                {
                    ToolTip = 'Specifies the status of the document.';
                }
                field("Date/Time Stamped"; "Date/Time Stamped")
                {
                    ToolTip = 'Specifies the date and time that the document received a digital stamp from the authorized service provider.';
                    Visible = false;
                }
                field("Date/Time Sent"; "Date/Time Sent")
                {
                    ToolTip = 'Specifies the date and time that the document was sent to the customer.';
                    Visible = false;
                }
                field("Date/Time Canceled"; "Date/Time Canceled")
                {
                    ToolTip = 'Specifies the date and time that the document was canceled.';
                    Visible = false;
                }
                field("Error Code"; "Error Code")
                {
                    ToolTip = 'Specifies the error code that the authorized service provider, PAC, has returned to Business Central.';
                    Visible = false;
                }
                field("Error Description"; "Error Description")
                {
                    ToolTip = 'Specifies the error message that the authorized service provider, PAC, has returned to Business Central.';
                    Visible = false;
                }
                field("Document Exchange Status"; "Document Exchange Status")
                {
                    ApplicationArea = Service;
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
            group("&Cr. Memo")
            {
                Caption = '&Cr. Memo';
                Image = CreditMemo;
                action(Statistics)
                {
                    Caption = 'Statistics';
                    Image = Statistics;
                    Promoted = true;
                    PromotedCategory = Process;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        OnBeforeCalculateSalesTaxStatistics(Rec);
                        if "Tax Area Code" = '' then
                            PAGE.RunModal(PAGE::"Service Credit Memo Statistics", Rec, "No.")
                        else
                            PAGE.RunModal(PAGE::"Service Credit Memo Stats.", Rec, "No.");
                    end;
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Service Comment Sheet";
                    RunPageLink = Type = CONST(General),
                                  "Table Name" = CONST("Service Cr.Memo Header"),
                                  "No." = FIELD("No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(processing)
        {
            group("&Electronic Document")
            {
                Caption = '&Electronic Document';
                action("S&end")
                {
                    Caption = 'S&end';
                    Ellipsis = true;
                    Image = SendTo;
                    ToolTip = 'Send an email to the customer with the electronic service credit memos attached as an XML file.';

                    trigger OnAction()
                    var
                        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(ServiceCrMemoHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if ServiceCrMemoHeader.FindSet then begin
                            repeat
                                ServiceCrMemoHeader.RequestStampEDocument;
                                ProgressWindow.Update(1, ServiceCrMemoHeader."No.");
                            until ServiceCrMemoHeader.Next = 0;
                        end;
                        ProgressWindow.Close;
                    end;
                }
                action("Export E-Document as &XML")
                {
                    Caption = 'Export E-Document as &XML';
                    Image = ExportElectronicDocument;
                    ToolTip = 'Export the posted service credit memos as electronic credit memos, XML files, and save them to a specified location.';

                    trigger OnAction()
                    begin
                        ExportEDocument;
                    end;
                }
                action("&Cancel")
                {
                    Caption = '&Cancel';
                    Image = Cancel;
                    ToolTip = 'Cancel the sending of the electronic service credit memos.';

                    trigger OnAction()
                    var
                        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
                        ProgressWindow: Dialog;
                    begin
                        CurrPage.SetSelectionFilter(ServiceCrMemoHeader);
                        ProgressWindow.Open(ProcessingInvoiceMsg);
                        if ServiceCrMemoHeader.FindSet then begin
                            repeat
                                ServiceCrMemoHeader.CancelEDocument;
                                ProgressWindow.Update(1, ServiceCrMemoHeader."No.");
                            until ServiceCrMemoHeader.Next = 0;
                        end;
                        ProgressWindow.Close;
                    end;
                }
                action(CFDIRelationDocuments)
                {
                    ApplicationArea = BasicMX;
                    Caption = 'CFDI Relation Documents';
                    Image = Allocations;
                    RunObject = Page "CFDI Relation Documents";
                    RunPageLink = "Document Table ID" = CONST(5994),
                                  "Document No." = FIELD("No."),
                                  "Customer No." = FIELD("Bill-to Customer No.");
                    RunPageMode = View;
                    ToolTip = 'View or add CFDI relation documents for the record.';
                }
            }
            action(SendCustom)
            {
                ApplicationArea = Service;
                Caption = 'Send';
                Ellipsis = true;
                Image = SendToMultiple;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Prepare to send the document according to the customer''s sending profile, such as attached to an email. The Send document to window opens first so you can confirm or select a sending profile.';

                trigger OnAction()
                begin
                    ServCrMemoHeader := Rec;
                    CurrPage.SetSelectionFilter(ServCrMemoHeader);
                    ServCrMemoHeader.SendRecords;
                end;
            }
            action("&Print")
            {
                ApplicationArea = Service;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                Promoted = true;
                PromotedCategory = Process;
                ToolTip = 'Prepare to print the document. A report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    CurrPage.SetSelectionFilter(ServCrMemoHeader);
                    ServCrMemoHeader.PrintRecords(true);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Service;
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
            action(ActivityLog)
            {
                ApplicationArea = Service;
                Caption = 'Activity Log';
                Image = Log;
                ToolTip = 'View the status and any errors if the document was sent as an electronic document or OCR file through the document exchange service.';

                trigger OnAction()
                var
                    ActivityLog: Record "Activity Log";
                begin
                    ActivityLog.ShowEntries(RecordId);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DocExchStatusStyle := GetDocExchStatusStyle;
    end;

    trigger OnAfterGetRecord()
    begin
        DocExchStatusStyle := GetDocExchStatusStyle;
    end;

    trigger OnOpenPage()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        SetSecurityFilterOnRespCenter;

        ServiceCrMemoHeader.CopyFilters(Rec);
        ServiceCrMemoHeader.SetFilter("Document Exchange Status", '<>%1', "Document Exchange Status"::"Not Sent");
        DocExchStatusVisible := not ServiceCrMemoHeader.IsEmpty;
    end;

    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        DocExchStatusStyle: Text;
        DocExchStatusVisible: Boolean;
        ProcessingInvoiceMsg: Label 'Processing record #1#######', Comment = '%1 = Record no';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateSalesTaxStatistics(var ServiceCrMemoHeader: Record "Service Cr.Memo Header")
    begin
    end;
}

