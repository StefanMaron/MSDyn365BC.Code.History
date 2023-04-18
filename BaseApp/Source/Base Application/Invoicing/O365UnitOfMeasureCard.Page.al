#if not CLEAN21
page 2198 "O365 Unit Of Measure Card"
{
    Caption = 'Price per';
    DataCaptionExpression = Description;
    SourceTable = "Unit of Measure";
    ObsoleteReason = 'Microsoft Invoicing has been discontinued.';
    ObsoleteState = Pending;
    ObsoleteTag = '21.0';

    layout
    {
        area(content)
        {
            field("Code"; Code)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                ToolTip = 'Specifies a code for the unit of measure that is shown on the item and resource cards where it is used.';
                Visible = false;
            }
            field(DescriptionInCurrentLanguage; DescriptionInCurrentLanguage)
            {
                ApplicationArea = Invoicing, Basic, Suite;
                Caption = 'Description';
                ToolTip = 'Specifies a description of the unit of measure.';

                trigger OnValidate()
                begin
                    if DescriptionInCurrentLanguage = '' then
                        DescriptionInCurrentLanguage := CopyStr(GetDescriptionInCurrentLanguage(), 1, MaxStrLen(DescriptionInCurrentLanguage));
                end;
            }
        }
    }

    actions
    {
        area(creation)
        {
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        DescriptionInCurrentLanguage := CopyStr(GetDescriptionInCurrentLanguage(), 1, MaxStrLen(DescriptionInCurrentLanguage));
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        if not (CloseAction in [ACTION::OK, ACTION::LookupOK]) then
            exit(true);

        if DescriptionInCurrentLanguage = CopyStr(GetDescriptionInCurrentLanguage(), 1, MaxStrLen(DescriptionInCurrentLanguage)) then
            exit(true);

        // Do not insert a new empty record
        if (Code = '') and (DescriptionInCurrentLanguage = '') then
            exit(true);

        if UnitOfMeasure.Get(UpperCase(CopyStr(DescriptionInCurrentLanguage, 1, MaxStrLen(Code)))) then
            Error(UnitOfMeasureAlredyExistsErr, DescriptionInCurrentLanguage);

        if Code = '' then
            InsertNewUnitOfMeasure()
        else
            RenameUnitOfMeasureRemoveTranslations();
    end;

    var
        UnitOfMeasureAlredyExistsErr: Label 'You already have a measure with the name %1.', Comment = '%1=The unit of measure description';
        DescriptionInCurrentLanguage: Text[10];

    local procedure RenameUnitOfMeasureRemoveTranslations()
    var
        UnitOfMeasureTranslation: Record "Unit of Measure Translation";
    begin
        if Code <> '' then begin
            UnitOfMeasureTranslation.SetRange(Code, Code);
            UnitOfMeasureTranslation.DeleteAll(true);
        end;

        Validate(Description, DescriptionInCurrentLanguage);
        Modify(true);
        Rename(CopyStr(DescriptionInCurrentLanguage, 1, MaxStrLen(Code)));
    end;

    local procedure InsertNewUnitOfMeasure()
    begin
        Validate(Code, CopyStr(DescriptionInCurrentLanguage, 1, MaxStrLen(Code)));
        Validate(Description, DescriptionInCurrentLanguage);

        Insert(true);
    end;
}
#endif
