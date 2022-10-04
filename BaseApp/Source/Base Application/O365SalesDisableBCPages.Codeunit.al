#if not CLEAN21
codeunit 2120 "O365 Sales Disable BC Pages"
{
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    trigger OnRun()
    begin
    end;

    var
        NotAccessibleInMicrosoftInvoicingErr: Label 'This page is currently not available in Microsoft Invoicing.\For more information, see %1.', Comment = '%1 = url to help page';
        NotAccessibleInMicrosoftInvoicingUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2005502', Locked = true;

    [EventSubscriber(ObjectType::Page, Page::"Data Classification Worksheet", 'OnOpenPageEvent', '', false, false)]
    [Scope('OnPrem')]
    procedure DisableDataClassificationWorksheet(var Rec: Record "Data Sensitivity")
    begin
        CheckInvoicingIdentityAndError();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableMyNotifications(var Rec: Record "My Notifications")
    begin
        CheckInvoicingIdentityAndError();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Application Area", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableApplicationArea(var Rec: Record "Application Area Buffer")
    begin
        CheckInvoicingIdentityAndError();
    end;

    [EventSubscriber(ObjectType::Page, Page::"O365 Device Setup", 'OnOpenPageEvent', '', false, false)]
    local procedure DisableO365DeviceSetup(var Rec: Record "O365 Device Setup Instructions")
    begin
        CheckInvoicingIdentityAndError();
    end;

    local procedure CheckInvoicingIdentityAndError()
    var
        EnvInfoProxy: Codeunit "Env. Info Proxy";
    begin
        if not EnvInfoProxy.IsInvoicing() then
            exit;

        Error(NotAccessibleInMicrosoftInvoicingErr, NotAccessibleInMicrosoftInvoicingUrlTxt);
    end;
}
#endif

