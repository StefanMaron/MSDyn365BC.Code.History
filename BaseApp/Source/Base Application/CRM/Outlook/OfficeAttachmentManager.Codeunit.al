codeunit 1629 "Office Attachment Manager"
{
    SingleInstance = true;

    trigger OnRun()
    begin
    end;

    var
        UrlOrContentString: Text;
        NameString: Text;
        Body: Text;
        "Count": Integer;

    procedure Add(FileUrlOrContent: Text; FileName: Text; BodyText: Text)
    begin
        if UrlOrContentString <> '' then begin
            UrlOrContentString += '|';
            NameString += '|';
        end;

        UrlOrContentString += FileUrlOrContent;
        NameString += FileName;
        if Body = '' then
            Body := BodyText;
        Count -= 1;
    end;

    procedure Ready(): Boolean
    begin
        exit(Count < 1);
    end;

    procedure Done()
    begin
        Count := 0;
        UrlOrContentString := '';
        NameString := '';
        Body := '';
    end;

    procedure GetFiles(): Text
    begin
        exit(UrlOrContentString);
    end;

    procedure GetNames(): Text
    begin
        exit(NameString);
    end;

    [Scope('OnPrem')]
    procedure GetBody(): Text
    var
        MailMgt: Codeunit "Mail Management";
    begin
        exit(MailMgt.ImageBase64ToUrl(Body));
    end;

    procedure IncrementCount(NewCount: Integer)
    begin
        Count += NewCount;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", 'OnSendSalesDocument', '', false, false)]
    local procedure OnSendSalesDocument(ShipAndInvoice: Boolean)
    begin
        if ShipAndInvoice then
            Count := 2;
    end;
}

