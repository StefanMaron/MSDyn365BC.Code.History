page 1074 "MS - PayPal Standard Settings"
{
    Caption = 'PayPal';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ModifyAllowed = false;
    PageType = Card;
    ShowFilter = false;
    SourceTable = 1070;

    layout
    {
        area(content)
        {
            group("PayPal Information")
            {
                Caption = 'PayPal Information';
                InstructionalText = 'Enter your email address for PayPal payments.';
                field(AccountID; PayPalAccountID)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Caption = 'PayPal Email';
                    ExtendedDatatype = EMail;

                    trigger OnValidate();
                    var
                        MSPayPalStandardMgt: Codeunit 1070;
                    begin
                        MSPayPalStandardMgt.SetPaypalAccount(PayPalAccountID, false);
                        if FindFirst() then;
                    end;
                }
                field("Terms of Service"; TermsOfServiceLbl)
                {
                    ApplicationArea = Invoicing, Basic, Suite;
                    Editable = false;
                    ShowCaption = false;

                    trigger OnDrillDown();
                    begin
                        Hyperlink("Terms of Service");
                    end;
                }

                group(SandboxGroup)
                {
                    Visible = IsSandbox;
                    field(SandboxControl; IsSandbox)
                    {
                        ApplicationArea = Invoicing, Basic, Suite;
                        Editable = false;
                        Caption = 'Sandbox active';
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord();
    begin
        PayPalAccountID := "Account ID";
        IsSandbox := (lowercase(GetTargetURL()) = lowercase(MSPayPalStandardMgt.GetSandboxURL()));
    end;

    trigger OnOpenPage();
    var
        TempPaymentServiceSetup: Record 1060 temporary;
        MSPayPalStandardTemplate: Record 1071;
    begin
        IF ISEMPTY() THEN BEGIN
            MSPayPalStandardMgt.RegisterPayPalStandardTemplate(TempPaymentServiceSetup);

            MSPayPalStandardMgt.GetTemplate(MSPayPalStandardTemplate);
            MSPayPalStandardTemplate.RefreshLogoIfNeeded();
            TRANSFERFIELDS(MSPayPalStandardTemplate, FALSE);
            INSERT(TRUE);
        END;
    end;

    var
        MSPayPalStandardMgt: Codeunit 1070;
        PayPalAccountID: Text[250];
        IsSandbox: Boolean;
        TermsOfServiceLbl: Label 'Terms of service';
}

