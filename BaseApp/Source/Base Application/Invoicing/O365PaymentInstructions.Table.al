table 2155 "O365 Payment Instructions"
{
    Caption = 'O365 Payment Instructions';
    ReplicateData = false;
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
#if CLEAN21
    ObsoleteState = Removed;
    ObsoleteTag = '24.0';
#else
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';
#endif

    fields
    {
        field(1; Id; Integer)
        {
            AutoIncrement = true;
            Caption = 'Id';
            DataClassification = SystemMetadata;
        }
        field(5; Name; Text[20])
        {
            Caption = 'Name';
        }
        field(6; "Payment Instructions"; Text[250])
        {
            Caption = 'Payment Instruction';
        }
        field(7; "Payment Instructions Blob"; BLOB)
        {
            Caption = 'Payment Instructions Blob';
        }
        field(8; Default; Boolean)
        {
            Caption = 'Default';
#if not CLEAN21
            trigger OnValidate()
            var
                O365PaymentInstructions: Record "O365 Payment Instructions";
            begin
                if Default then begin
                    O365PaymentInstructions.SetFilter(Id, '<>%1', Id);
                    O365PaymentInstructions.ModifyAll(Default, false, false);
                end;
            end;
#endif            
        }
    }

    keys
    {
        key(Key1; Id)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN21
    trigger OnDelete()
    var
        DocumentDescription: Text;
    begin
        if Default then
            Error(CannotDeleteDefaultErr);

        DocumentDescription := FindDraftsUsingInstructions();
        if DocumentDescription <> '' then
            Error(PaymentIsUsedErr, FindDraftsUsingInstructions());

        if GuiAllowed then
            if not Confirm(DoYouWantToDeleteQst) then
                Error('');

        DeleteTranslationsForRecord();
    end;

    var
        DocumentDescriptionTxt: Label '%1 %2', Comment = '%1=Document description (e.g. Invoice, Estimate,...); %2=Document Number';
        PaymentIsUsedErr: Label 'You cannot delete the Payment Instructions because at least one invoice (%1) is using them.', Comment = '%1: Document type and number';
        CannotDeleteDefaultErr: Label 'You cannot delete the default Payment Instructions.';
        Language: Codeunit Language;
        DoYouWantToDeleteQst: Label 'Are you sure you want to delete the payment instructions?';

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetPaymentInstructions(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Payment Instructions Blob");
        if not "Payment Instructions Blob".HasValue() then
            exit("Payment Instructions");
        "Payment Instructions Blob".CreateInStream(InStream, TEXTENCODING::Windows);
        exit(TypeHelper.ReadAsTextWithSeparator(InStream, TypeHelper.LFSeparator()));
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure SetPaymentInstructions(NewInstructions: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Payment Instructions Blob");
        "Payment Instructions" := CopyStr(NewInstructions, 1, MaxStrLen("Payment Instructions"));
        if StrLen(NewInstructions) <= MaxStrLen("Payment Instructions") then
            exit; // No need to store anything in the blob
        if NewInstructions = '' then
            exit;
        "Payment Instructions Blob".CreateOutStream(OutStream, TEXTENCODING::Windows);
        OutStream.WriteText(NewInstructions);
        Modify();
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure FindDraftsUsingInstructions() DocumentDescription: Text
    var
        SalesHeader: Record "Sales Header";
    begin
        DocumentDescription := '';
        if SalesHeader.FindFirst() then
            DocumentDescription := StrSubstNo(DocumentDescriptionTxt, SalesHeader.GetDocTypeTxt(), SalesHeader."No.");
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetNameInCurrentLanguage(): Text[20]
    var
        O365PaymentInstrTransl: Record "O365 Payment Instr. Transl.";
        LanguageCode: Code[10];
    begin
        LanguageCode := Language.GetLanguageCode(GlobalLanguage);

        if not O365PaymentInstrTransl.Get(Id, LanguageCode) then
            exit(Name);

        exit(O365PaymentInstrTransl."Transl. Name");
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure GetPaymentInstructionsInCurrentLanguage(): Text
    var
        O365PaymentInstrTransl: Record "O365 Payment Instr. Transl.";
        LanguageCode: Code[10];
    begin
        LanguageCode := Language.GetLanguageCode(GlobalLanguage);

        if not O365PaymentInstrTransl.Get(Id, LanguageCode) then
            exit(GetPaymentInstructions());

        exit(O365PaymentInstrTransl.GetTransPaymentInstructions());
    end;

    [Obsolete('Microsoft Invoicing has been discontinued.', '21.0')]
    procedure DeleteTranslationsForRecord()
    var
        O365PaymentInstrTransl: Record "O365 Payment Instr. Transl.";
    begin
        O365PaymentInstrTransl.SetRange(Id, Id);
        O365PaymentInstrTransl.DeleteAll(true);
    end;
#endif
}
