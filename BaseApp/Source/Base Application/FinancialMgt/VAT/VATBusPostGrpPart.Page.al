page 1878 "VAT Bus. Post. Grp Part"
{
    Caption = 'VAT Bus. Post. Grp Part';
    PageType = ListPart;
    SourceTable = "VAT Assisted Setup Bus. Grp.";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Selected; Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include';
                    ToolTip = 'Specifies if the VAT business posting group is included on the part.';

                    trigger OnValidate()
                    begin
                        if not Selected then
                            if CheckExistingCustomersAndVendorsWithVAT(Code) then begin
                                TrigerNotification(VATBusGrpExistingDataErrorMsg);
                                Selected := true;
                            end;
                    end;
                }
                field("Code"; Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the posting group that determines how to calculate and post VAT for customers and vendors. The number of VAT posting groups that you set up can depend on local legislation and whether you trade both domestically and internationally.';

                    trigger OnValidate()
                    begin
                        if (Code <> xRec.Code) and (xRec.Code <> '') then
                            if CheckExistingCustomersAndVendorsWithVAT(xRec.Code) then begin
                                TrigerNotification(VATBusGrpExistingDataErrorMsg);
                                Error('');
                            end;
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the VAT business posting group.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnDeleteRecord(): Boolean
    begin
        if CheckExistingCustomersAndVendorsWithVAT(Code) then begin
            TrigerNotification(VATBusGrpExistingDataErrorMsg);
            exit(false);
        end;
        if Count = 1 then begin
            TrigerNotification(VATBusGrpEmptyErrorMsg);
            exit(false);
        end;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Selected := true;
    end;

    trigger OnOpenPage()
    begin
        VATBusGrpNotification.Id := Format(CreateGuid());
        PopulateVATBusGrp();
        Selected := true;
        SetRange(Default, false);
    end;

    var
        VATBusGrpNotification: Notification;
        VATBusGrpExistingDataErrorMsg: Label 'You can''t change or delete the VAT business posting group because it''s already been used to post VAT for transactions.';
        VATBusGrpEmptyErrorMsg: Label 'You can''t delete the record because the VAT setup would be empty.';

    local procedure TrigerNotification(NotificationMsg: Text)
    begin
        VATBusGrpNotification.Recall();
        VATBusGrpNotification.Message(NotificationMsg);
        VATBusGrpNotification.Send();
    end;

    procedure HideNotification()
    var
        DummyGuid: Guid;
    begin
        if VATBusGrpNotification.Id = DummyGuid then
            exit;
        VATBusGrpNotification.Message := '';
        VATBusGrpNotification.Recall();
    end;
}

