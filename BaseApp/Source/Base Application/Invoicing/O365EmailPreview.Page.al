#if not CLEAN21
page 2159 "O365 Email Preview"
{
    Caption = 'Email Preview';
    Editable = false;
    PageType = Card;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            usercontrol(BodyHTMLMessage; "Microsoft.Dynamics.Nav.Client.WebPageViewer")
            {
                ApplicationArea = Invoicing, Basic, Suite;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    CurrPage.BodyHTMLMessage.LinksOpenInNewWindow();
                    CurrPage.BodyHTMLMessage.SetContent(BodyText);
                end;

                trigger DocumentReady()
                begin
                end;

                trigger Callback(data: Text)
                begin
                end;

                trigger Refresh(callbackUrl: Text)
                begin
                    CurrPage.BodyHTMLMessage.LinksOpenInNewWindow();
                    CurrPage.BodyHTMLMessage.SetContent(BodyText);
                end;
            }
        }
    }

    actions
    {
    }

    var
        BodyText: Text;

    [Scope('OnPrem')]
    procedure LoadHTMLFile(FileName: Text)
    var
        HTMLFile: File;
        InStream: InStream;
        TextLine: Text;
        Pos: Integer;
    begin
        HTMLFile.Open(FileName, TEXTENCODING::UTF8);
        HTMLFile.CreateInStream(InStream);
        while not InStream.EOS do begin
            InStream.ReadText(TextLine, 1000);
            BodyText := BodyText + TextLine;
        end;

        Pos := StrPos(LowerCase(BodyText), '<html');
        BodyText := CopyStr(BodyText, Pos);
        HTMLFile.Close();
    end;

    procedure GetBodyText(): Text
    begin
        exit(BodyText);
    end;
}
#endif
