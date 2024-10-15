page 17362 "General Directory"
{
    ApplicationArea = Basic, Suite;
    Caption = 'General Directory';
    DataCaptionFields = Type;
    PageType = Worksheet;
    SourceTable = "General Directory";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentType; CurrentType)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Type';
                OptionCaption = ' ,,,,,,Hire Condition,,,,Military Agency,Military Composition,Military Office,Anketa Print,Special,Tax Payer Category,,,Additional Tariff,Territor. Condition,Special Work Condition,Countable Service Reason,Countable Service Addition,Long Service,Other Absence';

                trigger OnValidate()
                begin
                    CurrentTypeOnAfterValidate;
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the related record.';
                }
                field("Full Name"; "Full Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Note; Note)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the note text or if a note exists.';
                }
                field("XML Element Type"; "XML Element Type")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if GetFilter(Type) = '' then begin
            CurrentType := 0;
            SetRange(Type, CurrentType);
        end else
            if GetRangeMin(Type) = GetRangeMax(Type) then
                CurrentType := GetRangeMin(Type);
    end;

    var
        CurrentType: Option " ",,,,,,"Hire Condition",,,,"Military Agency","Military Composition","Military Office","Anketa Print",Special,"Tax Payer Category",,,"Additional Tariff","Territor. Condition","Special Work Condition","Countable Service Reason","Countable Service Addition","Long Service","Other Absence";

    local procedure CurrentTypeOnAfterValidate()
    begin
        SetRange(Type, CurrentType);
        CurrPage.Update(false);
    end;
}

