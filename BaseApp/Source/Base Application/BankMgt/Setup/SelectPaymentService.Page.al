namespace Microsoft.Bank.Setup;

page 1061 "Select Payment Service"
{
    Caption = 'Select Payment Service';
    DataCaptionExpression = '';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = StandardDialog;
    SourceTable = "Payment Service Setup";

    layout
    {
        area(content)
        {
            repeater(Control3)
            {
                ShowCaption = false;
                field(Available; Rec.Available)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the icon and link to the payment service will be inserted on the outgoing sales document.';

                    trigger OnValidate()
                    begin
                        if not Rec.Available then
                            DeselectedValue := true;
                    end;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the name of the payment service.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description of the payment service.';
                }
            }
            field(SetupPaymentServices; SetupPaymentServicesLbl)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'SetupPaymentServices';
                Editable = false;
                ShowCaption = false;

                trigger OnDrillDown()
                begin
                    CurrPage.Close();
                    PAGE.Run(PAGE::"Payment Services");
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempPaymentServiceSetup: Record "Payment Service Setup" temporary;
    begin
        if CloseAction in [ACTION::Cancel, ACTION::LookupCancel] then
            exit;

        if DeselectedValue then
            exit(true);

        TempPaymentServiceSetup.Copy(Rec, true);
        TempPaymentServiceSetup.SetRange(Available, true);
        if not TempPaymentServiceSetup.FindFirst() then
            exit(Confirm(NoPaymentServicesSelectedQst));
    end;

    var
        DeselectedValue: Boolean;
        NoPaymentServicesSelectedQst: Label 'To enable the payment service for the document, you must select the Available check box.\\Are you sure you want to exit?';
        SetupPaymentServicesLbl: Label 'Set Up Payment Services';
}

