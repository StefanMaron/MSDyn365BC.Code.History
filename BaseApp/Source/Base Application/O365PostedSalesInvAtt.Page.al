page 2121 "O365 Posted Sales Inv. Att."
{
    Caption = 'Attachments';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    PromotedActionCategories = 'New,Process,Report,Manage';
    SourceTable = "Sales Invoice Header";

    layout
    {
        area(content)
        {
            part(PhoneIncomingDocAttachFactBox; "O365 Incoming Doc. Attch. List")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Attachments';
                ShowFilter = false;
                SubPageLink = "Posting Date" = FIELD("Posting Date"),
                              "Document No." = FIELD("No.");
                Visible = IsPhone;
            }
            part(WebIncomingDocAttachFactBox; "BC O365 Inc. Doc. Attch. List")
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Attachments';
                ShowFilter = false;
                SubPageLink = "Posting Date" = FIELD("Posting Date"),
                              "Document No." = FIELD("No.");
                Visible = NOT IsPhone;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ImportNewPhone)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Attach Picture';
                Image = Attach;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Attach a picture to the invoice.';
                Visible = IsPhone;

                trigger OnAction()
                begin
                    CurrPage.PhoneIncomingDocAttachFactBox.PAGE.ImportNewFile;
                end;
            }
            action(ImportNewWeb)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Add Attachments';
                Image = Attach;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Attach an attachment to the invoice.';
                Visible = NOT IsPhone;

                trigger OnAction()
                begin
                    CurrPage.WebIncomingDocAttachFactBox.PAGE.ImportNewFile;
                end;
            }
            action(TakePicture)
            {
                ApplicationArea = Basic, Suite, Invoicing;
                Caption = 'Take Picture';
                Gesture = None;
                Image = Camera;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = true;
                PromotedOnly = true;
                ToolTip = 'Activate the camera on the device.';
                Visible = CameraAvailable;

                trigger OnAction()
                begin
                    if IsPhone then
                        CurrPage.PhoneIncomingDocAttachFactBox.PAGE.TakeNewPicture
                    else
                        CurrPage.WebIncomingDocAttachFactBox.PAGE.TakeNewPicture;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsPhone := ClientTypeManagement.GetCurrentClientType = CLIENTTYPE::Phone;
        if IsPhone then
            CameraAvailable := CurrPage.PhoneIncomingDocAttachFactBox.PAGE.GetCameraAvailable
        else
            CameraAvailable := CurrPage.WebIncomingDocAttachFactBox.PAGE.GetCameraAvailable;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        CameraAvailable: Boolean;
        IsPhone: Boolean;
}

