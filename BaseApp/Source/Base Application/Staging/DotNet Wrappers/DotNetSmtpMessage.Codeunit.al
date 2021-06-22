codeunit 3031 DotNet_SmtpMessage
{

    trigger OnRun()
    begin
    end;

    var
        DotNetSmtpMessage: DotNet SmtpMessage;

    procedure CreateMessage()
    begin
        DotNetSmtpMessage := DotNetSmtpMessage.SmtpMessage;
    end;

    procedure SetFromAddress(FromAddress: Text)
    begin
        DotNetSmtpMessage.FromAddress := FromAddress;
    end;

    procedure SetFromName(FromName: Text)
    begin
        DotNetSmtpMessage.FromName := FromName;
    end;

    procedure SetToAddress(ToAddress: Text)
    begin
        DotNetSmtpMessage."To" := ToAddress;
    end;

    procedure SetSubject(Subject: Text)
    begin
        DotNetSmtpMessage.Subject := Subject;
    end;

    procedure SetAsHtmlFormatted(HtmlFormatted: Boolean)
    begin
        DotNetSmtpMessage.HtmlFormatted := HtmlFormatted;
    end;

    procedure SetTimeout(Timeout: Integer)
    begin
        DotNetSmtpMessage.Timeout := Timeout;
    end;

    procedure ClearBody()
    begin
        DotNetSmtpMessage.Body := '';
    end;

    procedure AppendToBody(Text: Text)
    begin
        DotNetSmtpMessage.AppendBody(Text);
    end;

    procedure AddRecipients(AddressToAdd: Text)
    begin
        DotNetSmtpMessage.AddRecipients(AddressToAdd);
    end;

    procedure AddCC(AddressToAdd: Text)
    begin
        DotNetSmtpMessage.AddCC(AddressToAdd);
    end;

    procedure AddBCC(AddressToAdd: Text)
    begin
        DotNetSmtpMessage.AddBCC(AddressToAdd);
    end;

    procedure AddAttachment(AttachmentStream: InStream; AttachmentName: Text)
    begin
        DotNetSmtpMessage.AddAttachment(AttachmentStream, AttachmentName);
    end;

    procedure SendMail(ServerName: Text; ServerPort: Integer; UseAuthentication: Boolean; Username: Text; Password: Text; UseSSL: Boolean): Text
    begin
        exit(DotNetSmtpMessage.Send(ServerName, ServerPort, UseAuthentication, Username, Password, UseSSL));
    end;

    procedure ConvertBase64ImagesToContentId(): Boolean
    begin
        exit(DotNetSmtpMessage.ConvertBase64ImagesToContentId());
    end;

    [Scope('OnPrem')]
    procedure GetSmtpMessage(var DotNetSmtpMessage2: DotNet SmtpMessage)
    begin
        DotNetSmtpMessage2 := DotNetSmtpMessage;
    end;

    [Scope('OnPrem')]
    procedure SetSmtpMessage(DotNetSmtpMessage2: DotNet SmtpMessage)
    begin
        DotNetSmtpMessage := DotNetSmtpMessage2;
    end;
}

