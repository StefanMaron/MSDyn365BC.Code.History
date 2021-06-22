page 1879 "VAT Product Posting Grp Part"
{
    Caption = 'VAT Product Posting Grp Part';
    PageType = ListPart;
    SourceTable = "VAT Setup Posting Groups";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Selected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether to include the VAT product posting group on the line.';
                    Visible = VATRatesGroup;

                    trigger OnValidate()
                    begin
                        if Selected then
                            exit;

                        if CheckExistingItemAndServiceWithVAT(xRec."VAT Prod. Posting Group", xRec."Application Type" = "Application Type"::Services) then begin
                            TrigerNotification(VATDeleteIsNotallowedErr);
                            Error('');
                        end;
                    end;
                }
                field("VAT Prod. Posting Group"; "VAT Prod. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';

                    trigger OnValidate()
                    begin
                        if CheckExistingItemAndServiceWithVAT(xRec."VAT Prod. Posting Group", xRec."Application Type" = "Application Type"::Services) then begin
                            TrigerNotification(VATDeleteIsNotallowedErr);
                            Error('');
                        end;
                    end;
                }
                field("Application Type"; "Application Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how a cost recipient is linked to its cost source to provide cost forwarding according to the costing method.';
                    Visible = VATRatesGroup;

                    trigger OnValidate()
                    begin
                        if CheckExistingItemAndServiceWithVAT(xRec."VAT Prod. Posting Group", xRec."Application Type" = "Application Type"::Services) then begin
                            TrigerNotification(VATDeleteIsNotallowedErr);
                            Error('');
                        end;
                    end;
                }
                field("VAT Prod. Posting Grp Desc."; "VAT Prod. Posting Grp Desc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT product posting group.';
                    Visible = VATRatesGroup;
                }
                field("VAT %"; "VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT percentage used.';
                    Visible = VATRatesGroup;
                    Width = 3;
                }
                field("Sales VAT Account"; "Sales VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post sales VAT, for the particular combination of VAT business posting group and VAT product posting group.';
                    Visible = VATAccountsGroup;
                }
                field("Purchase VAT Account"; "Purchase VAT Account")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which to post purchase VAT.';
                    Visible = VATAccountsGroup;
                }
                field("Reverse Chrg. VAT Acc."; "Reverse Chrg. VAT Acc.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the general ledger account number to which you want to post reverse charge VAT (purchase VAT) for this combination of VAT business posting group and VAT product posting group, if you have selected the Reverse Charge VAT option in the VAT Calculation Type field.';
                    Visible = VATAccountsGroup;
                }
                field("VAT Clause Desc"; "VAT Clause Desc")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT clause.';
                    Visible = VATClausesGroup;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if CheckExistingItemAndServiceWithVAT("VAT Prod. Posting Group", "Application Type" = "Application Type"::Services) then begin
            TrigerNotification(VATDeleteIsNotallowedErr);
            exit(false);
        end;
        if VATAccountsGroup or VATClausesGroup then begin
            SetRange(Selected, true);
            if Count = 1 then begin
                TrigerNotification(VATEmptyErrorMsg);
                exit(false);
            end;
        end;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if VATAccountsGroup or VATClausesGroup then
            Error(VATAddIsNotallowedErr);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Validate(Selected, true);
        Validate(Default, false);
        Validate("Application Type", "Application Type"::Items);
    end;

    trigger OnOpenPage()
    begin
        VATNotification.Id := Format(CreateGuid);
        PopulateVATProdGroups;
        ShowVATRates;
        SetRange(Default, false);
    end;

    var
        VATNotification: Notification;
        VATRatesGroup: Boolean;
        VATAccountsGroup: Boolean;
        VATClausesGroup: Boolean;
        VATAddIsNotallowedErr: Label 'You can''t add accounts now because they won''t have settings like VAT rates. Go back to the VAT Rates for Items and Services page, add a line, and continue.';
        VATDeleteIsNotallowedErr: Label 'You can''t delete or modify this VAT record because it is connected to existing item.';
        VATEmptyErrorMsg: Label 'You can''t delete the record because the VAT setup would be empty.';

    procedure ShowVATRates()
    begin
        ResetView;
        VATRatesGroup := true;
        Reset;
        SetRange(Default, false);
        CurrPage.Update;
    end;

    procedure ShowVATAccounts()
    begin
        ResetView;
        VATAccountsGroup := true;
        ShowOnlySelectedSrvItem;
    end;

    procedure ShowVATClauses()
    begin
        ResetView;
        VATClausesGroup := true;
        ShowOnlySelectedSrvItem;
    end;

    local procedure ResetView()
    begin
        VATNotification.Recall;
        VATRatesGroup := false;
        VATAccountsGroup := false;
        VATClausesGroup := false;
    end;

    local procedure ShowOnlySelectedSrvItem()
    begin
        SetRange(Selected, true);
        CurrPage.Update;
    end;

    local procedure TrigerNotification(NotificationMsg: Text)
    begin
        VATNotification.Recall;
        VATNotification.Message(NotificationMsg);
        VATNotification.Send;
    end;

    procedure HideNotification()
    var
        DummyGuid: Guid;
    begin
        if VATNotification.Id = DummyGuid then
            exit;
        VATNotification.Message := '';
        VATNotification.Recall;
    end;
}

