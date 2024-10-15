codeunit 31122 "EET Send Entries To Service"
{

    trigger OnRun()
    begin
        with EETEntry do begin
            SetCurrentKey("EET Status");
            SetFilter("EET Status", '%1|%2|%3|%4',
              "EET Status"::"Send Pending", "EET Status"::Failure,
              "EET Status"::Verified, "EET Status"::"Verified with Warnings");
            if FindSet then
                repeat
                    EETEntry2.Get("Entry No.");
                    EETEntryMgt.SendEntryToService(EETEntry2, false);
                until Next = 0;
        end;
    end;

    var
        EETEntry: Record "EET Entry";
        EETEntry2: Record "EET Entry";
        EETEntryMgt: Codeunit "EET Entry Management";
}

