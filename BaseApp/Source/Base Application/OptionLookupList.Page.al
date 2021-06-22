page 1670 "Option Lookup List"
{
    Caption = 'Option Lookup List';
    Editable = false;
    PageType = List;
    SourceTable = "Option Lookup Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Option Caption"; "Option Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of transaction you want to make. The value in this field determines what you can select in the No. field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        OptionLookupBuffer: Record "Option Lookup Buffer";
    begin
        if GetFilter("Lookup Type") = '' then
            exit;

        Evaluate(OptionLookupBuffer."Lookup Type", GetFilter("Lookup Type"));
        FillBuffer(OptionLookupBuffer."Lookup Type");
        SetCurrentKey(ID);
    end;
}

