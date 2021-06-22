table 2170 "O365 Default Email Message"
{
    Caption = 'O365 Default Email Message';
    ReplicateData = false;

    fields
    {
        field(1; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Invoice';
            OptionMembers = Quote,Invoice;
        }
        field(10; Value; BLOB)
        {
            Caption = 'Value';
        }
    }

    keys
    {
        key(Key1; "Document Type")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GreetingTxt: Label 'Hello <%1>,', Comment = '%1 - customer name';
        InvoiceEmailBodyTxt: Label 'Thank you for your business. Your invoice is attached to this message.';
        QuoteEmailBodyTxt: Label 'As promised, here is our estimate. Please see the attached estimate for details.';
        CustomerLbl: Label 'Customer';
        TestInvoiceEmailBodyTxt: Label 'Thank you for your business. Your test invoice is attached to this message.';

    local procedure CreateMissingDefaultMessages()
    var
        InvoiceO365DefaultEmailMsg: Record "O365 Default Email Message";
        QuoteO365DefaultEmailMsg: Record "O365 Default Email Message";
        CR: Text[1];
    begin
        CR[1] := 10;

        if not Get("Document Type"::Quote) then begin
            // Create default estimate message
            QuoteO365DefaultEmailMsg."Document Type" := "Document Type"::Quote;
            QuoteO365DefaultEmailMsg.Insert();
            QuoteO365DefaultEmailMsg.SetMessage(StrSubstNo(GreetingTxt, CustomerLbl) + CR + CR + QuoteEmailBodyTxt)
        end;

        if not Get("Document Type"::Invoice) then begin
            // Create default invoice message
            InvoiceO365DefaultEmailMsg."Document Type" := "Document Type"::Invoice;
            InvoiceO365DefaultEmailMsg.Insert();
            InvoiceO365DefaultEmailMsg.SetMessage(StrSubstNo(GreetingTxt, CustomerLbl) + CR + CR + InvoiceEmailBodyTxt)
        end;
    end;

    procedure GetMessage(Type: Option): Text
    begin
        SetFilter("Document Type", '%1', Type);
        if not FindFirst then begin
            CreateMissingDefaultMessages;
            SetFilter("Document Type", '%1', Type);
            FindFirst
        end;
        exit(ReadMessage);
    end;

    procedure ReadMessage(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields(Value);
        Value.CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator));
    end;

    procedure SetMessage(NewMessage: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Value);
        Value.CreateOutStream(OutStr, TEXTENCODING::Windows);
        OutStr.WriteText(NewMessage);
        Modify(true);
    end;

    procedure ReportUsageToDocumentType(var DocumentType: Option; ReportUsage: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        case ReportUsage of
            ReportSelections.Usage::"S.Invoice", ReportSelections.Usage::"S.Invoice Draft", ReportSelections.Usage::"P.Invoice":
                DocumentType := "Document Type"::Invoice;
            ReportSelections.Usage::"S.Quote", ReportSelections.Usage::"P.Quote":
                DocumentType := "Document Type"::Quote;
        end;
    end;

    procedure GetTestInvoiceMessage(): Text
    var
        CR: Text[1];
        EmailBodyTxt: Text;
    begin
        CR[1] := 10;

        // Create test invoice body message
        EmailBodyTxt := StrSubstNo(GreetingTxt, CustomerLbl) + CR + CR + TestInvoiceEmailBodyTxt;

        exit(EmailBodyTxt)
    end;
}

