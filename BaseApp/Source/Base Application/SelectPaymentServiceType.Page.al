page 1062 "Select Payment Service Type"
{
    Caption = 'Select Payment Service Type';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Payment Service Setup";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control4)
            {
                Editable = false;
                ShowCaption = false;
                field(Name; Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the payment service type.';
                }
                field(Description; Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the payment service.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        OnRegisterPaymentServiceProviders(Rec);
    end;
}

