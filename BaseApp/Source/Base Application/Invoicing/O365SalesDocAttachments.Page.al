#if not CLEAN21
page 2120 "O365 Sales Doc. Attachments"
{
    Caption = 'Attachments';
    DataCaptionFields = "Sell-to Customer Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    SourceTable = "Sales Header";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            part(PhoneIncomingDocAttachFactBox; "O365 Incoming Doc. Attch. List")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Attachments';
                ShowFilter = false;
                SubPageLink = "Incoming Document Entry No." = FIELD("Incoming Document Entry No.");
                Visible = IsPhone;
            }
            part(WebIncomingDocAttachFactBox; "BC O365 Inc. Doc. Attch. List")
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Attachments';
                ShowFilter = false;
                SubPageLink = "Incoming Document Entry No." = FIELD("Incoming Document Entry No.");
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
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Attach Picture';
                Image = Attach;
                ToolTip = 'Attach a picture to the invoice.';
                Visible = IsPhone;

                trigger OnAction()
                begin
                    CurrPage.PhoneIncomingDocAttachFactBox.PAGE.ImportNewFile();
                end;
            }
            action(ImportNewWeb)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Add Attachments';
                Image = Attach;
                ToolTip = 'Attach an attachment to the invoice.';
                Visible = NOT IsPhone;

                trigger OnAction()
                begin
                    CurrPage.WebIncomingDocAttachFactBox.PAGE.ImportNewFile();
                end;
            }
            action(TakePicture)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Take Picture';
                Gesture = None;
                Image = Camera;
                ToolTip = 'Activate the camera on the device.';
                Visible = CameraAvailable;

                trigger OnAction()
                begin
                    if IsPhone then
                        CurrPage.PhoneIncomingDocAttachFactBox.PAGE.TakeNewPicture()
                    else
                        CurrPage.WebIncomingDocAttachFactBox.PAGE.TakeNewPicture();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Manage', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(ImportNewPhone_Promoted; ImportNewPhone)
                {
                }
                actionref(ImportNewWeb_Promoted; ImportNewWeb)
                {
                }
                actionref(TakePicture_Promoted; TakePicture)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsPhone := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;
        if IsPhone then
            CameraAvailable := CurrPage.PhoneIncomingDocAttachFactBox.PAGE.GetCameraAvailable()
        else
            CameraAvailable := CurrPage.WebIncomingDocAttachFactBox.PAGE.GetCameraAvailable();
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";
        CameraAvailable: Boolean;
        IsPhone: Boolean;
}
#endif
