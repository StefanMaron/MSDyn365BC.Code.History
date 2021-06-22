table 5928 "Service Status Priority Setup"
{
    Caption = 'Service Status Priority Setup';
    DrillDownPageID = "Service Order Status Setup";
    LookupPageID = "Service Order Status Setup";

    fields
    {
        field(1; "Service Order Status"; Option)
        {
            Caption = 'Service Order Status';
            OptionCaption = 'Pending,In Process,Finished,On Hold';
            OptionMembers = Pending,"In Process",Finished,"On Hold";
        }
        field(2; Priority; Option)
        {
            Caption = 'Priority';
            OptionCaption = 'High,Medium High,Medium Low,Low';
            OptionMembers = High,"Medium High","Medium Low",Low;

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if Priority <> xRec.Priority then begin
                    ServStatusPrioritySetup.Reset();
                    ServStatusPrioritySetup.SetRange(Priority, Priority);
                    if ServStatusPrioritySetup.FindFirst then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text000, FieldCaption(Priority), Format(Priority),
                               FieldCaption("Service Order Status"), Format("Service Order Status")), true)
                        then
                            Priority := xRec.Priority;

                    RepairStatus.Reset();
                    RepairStatus.SetRange("Service Order Status", "Service Order Status");
                    RepairStatus.ModifyAll(Priority, Priority);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Service Order Status")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        Text000: Label '%1 %2 is already used with %3 %4.\\Do you want to continue?';
        ServStatusPrioritySetup: Record "Service Status Priority Setup";
        RepairStatus: Record "Repair Status";
}

