codeunit 12112 "IT - Report Management"
{

    trigger OnRun()
    begin
    end;

    var
        UnpostedSalesDocumentsErr: Label 'An unposted sales document with posting number %1 exists, which you must post before you can continue.\\%2.', Comment='%1=Posting No.,%2=Sales Header RecordID';
        UnpostedPurchDocumentsErr: Label 'An unposted purchase document with posting number %1 exists, which you must post before you can continue.\\%2.', Comment='%1=Posting No.,%2=Purchase Header RecordID';
        UnpostedSalesDocumentsMsg: Label 'An unposted sales document with posting number %1 exists.\\%2.', Comment='%1=Posting No.,%2=Sales Header RecordID';
        UnpostedPurchDocumentsMsg: Label 'An unposted puchase document with posting number %1 exists.\\%2.', Comment='%1=Posting No.,%2=Purchase Header RecordID';

    procedure CheckSalesDocNoGaps(MaxDate: Date; ThrowError: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetFilter("Posting No.", '<>%1', '');
        if MaxDate <> 0D then
            SalesHeader.SetFilter("Posting Date", '<=%1', MaxDate);
        if not SalesHeader.FindFirst then
            exit;
        if ThrowError then
            Error(
              UnpostedSalesDocumentsErr, SalesHeader."Posting No.", SalesHeader.RecordId);

        Message(
          UnpostedSalesDocumentsMsg, SalesHeader."Posting No.", SalesHeader.RecordId);
    end;

    procedure CheckPurchDocNoGaps(MaxDate: Date; ThrowError: Boolean)
    var
        PurchHeader: Record "Purchase Header";
    begin
        PurchHeader.SetFilter("Posting No.", '<>%1', '');
        if MaxDate <> 0D then
            PurchHeader.SetFilter("Posting Date",'<=%1', MaxDate);
        if not PurchHeader.FindFirst then
            exit;

        if ThrowError then
            Error(
              UnpostedPurchDocumentsErr, PurchHeader."Posting No.", PurchHeader.RecordId);

        Message(
          UnpostedPurchDocumentsMsg, PurchHeader."Posting No.", PurchHeader.RecordId);
    end;
}

