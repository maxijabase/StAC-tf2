#pragma semicolon 1

/********** OnPlayerRunCmd Detections **********/

/*
    in OnPlayerRunCmd, we check for:
    - CMDNUM SPIKES
    - SILENT AIM
    - AIM SNAPS
    - FAKE ANGLES
    - TURN BINDS

    TODO: nullcmd spamming
*/

/*

    X pitch +down/-up
    Y yaw +left/-right
    Z roll +right/-left

*/

int PITCH   = 0;
int YAW     = 1;
int ROLL    = 2;

public void OnPlayerRunCmdPre
(
    int cl,
    int buttons,
    int impulse,
    const float vel[3],
    const float angles[3],
    int weapon,
    int subtype,
    int cmdnum,
    int tickcount,
    int seed,
    const int mouse[2]
)
{
    PlayerRunCmd(cl, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);
}

public Action OnPlayerRunCmd
(
    int cl,
    int& buttons,
    int& impulse,
    float vel[3],
    float angles[3],
    int& weapon,
    int& subtype,
    int& cmdnum,
    int& tickcount,
    int& seed,
    int mouse[2]
)
{
    if ( !IsClientConnected(cl) || !IsClientInGame(cl) || IsClientInKickQueue(cl) )
    {
        // Todo; maybe KickClient for the IsClientInGame failing here?
        // Can this cause airstuck??
        buttons     = 0;
        impulse     = 0;
        vel         = {0.0, 0.0, 0.0};
        angles      = {0.0, 0.0, 0.0};
        weapon      = 0;
        subtype     = 0;
        cmdnum      = 0;
        tickcount   = 0;
        seed        = 0;
        mouse       = {0, 0};

        timeSinceNullCmd[cl] = GetEngineTime();
        return Plugin_Continue;
    }


    // Something nasty is happening
    /*
    if (tickcount > GetGameTickCount() || cmdnum > GetSequenceNumber(cl) )
    {
        //
    }
    */

    OnPlayerRunCmd_jaypatch(cl, buttons, impulse, vel, angles, weapon, subtype, cmdnum, tickcount, seed, mouse);

    // Don't allow clients to have both left and right turns active
    if (buttons & IN_LEFT && buttons & IN_RIGHT)
    {
        buttons &= ~( IN_LEFT | IN_RIGHT );
    }
    return Plugin_Continue;
}



/*
    void CInput::CreateMove ( int sequence_number, float input_sample_frametime, bool active )
    {
        CUserCmd *cmd = &m_pCommands[ sequence_number % MULTIPLAYER_BACKUP ];
        CVerifiedUserCmd *pVerified = &m_pVerifiedCommands[ sequence_number % MULTIPLAYER_BACKUP ];

        cmd->Reset();

        cmd->command_number = sequence_number;
        cmd->tick_count     = gpGlobals->tickcount;

        ...
    }

    // For matching server and client commands for debugging
    int     command_number;

    // the tick the client created this command
    int     tick_count;

    // Player instantaneous view angles.
    QAngle  viewangles;

    // Intended velocities
    //  forward velocity.
    float   forwardmove;

    //  sideways velocity.
    float   sidemove;

    //  upward velocity.
    float   upmove;

    // Attack button states
    int     buttons;

    // Impulse command issued.
    byte    impulse;

    // Current weapon id
    int     weaponselect;
    int     weaponsubtype;

    int     random_seed;        // For shared random functions
#ifdef GAME_DLL
    int     server_random_seed; // Only the server populates this seed
#endif

    short   mousedx;            // mouse accum in x from create move
    short   mousedy;            // mouse accum in y from create move
*/
stock void PlayerRunCmd
(
    const int cl,
    const int buttons,
    const int impulse,
    const float vel[3],
    const float angles[3],
    const int weapon,
    const int subtype,
    const int cmdnum,
    const int tickcount,
    const int seed,
    const int mouse[2]
)
{
    //Profiler prof = CreateProfiler();
    //StartProfiling(prof);

    // make sure client is real & not a bot
    if (!IsValidClient(cl))
    {
        return;
    }

    // you NEED to move this to OnGameFrame()
    // int servertickcount = GetGameTickCount();

    //if (tickbase > servertickcount || tickcount > servertickcount)
    //{
    //    // LogMessage("->");
    //}

    // point_worldtext_TODO(cl);


    // originally from ssac - block invalid usercmds with invalid data
    // todo: do we really still need this...
    if (cmdnum <= 0 || tickcount <= 0)
    {
        if (cmdnum < 0 || tickcount < 0)
        {
            // need this basically no matter what
            int userid = GetClientUserId(cl);

            StacLog("cmdnum %i, tickcount %i", cmdnum, tickcount);
            StacGeneralPlayerNotify(userid, "Client has invalid usercmd data!");
            return;
        }
        timeSinceNullCmd[cl] = GetEngineTime();
        return;
    }

    // + around 1µs
    // grab engine time
    for (int i = 2; i > 0; --i)
    {
        engineTime[cl][i] = engineTime[cl][i-1];
    }
    engineTime[cl][0] = GetEngineTime();

    // calc client cmdrate
    calcTPSfor(cl);

    // + around 4µs
    {
        // grab angles
        for (int i = 4; i > 0; --i)
        {
            clangles[cl][i] = clangles[cl][i-1];
        }
        clangles[cl][0] = angles;

        // grab cmdnum
        for (int i = 4; i > 0; --i)
        {
            clcmdnum[cl][i] = clcmdnum[cl][i-1];
        }
        clcmdnum[cl][0] = cmdnum;

        // grab tickccount
        for (int i = 4; i > 0; --i)
        {
            cltickcount[cl][i] = cltickcount[cl][i-1];
        }
        cltickcount[cl][0] = tickcount;

        // grab buttons
        for (int i = 4; i > 0; --i)
        {
            clbuttons[cl][i] = clbuttons[cl][i-1];
        }
        clbuttons[cl][0] = buttons;

        // grab mouse
        clmouse[cl] = mouse;
    }

    // + around 1µs
    {
        // grab position
        clpos[cl][1] = clpos[cl][0];
        GetClientEyePosition(cl, clpos[cl][0]);
    }


    // + around 1µs
    {
        // did we hurt someone in any of the past few frames?
        didHurtOnFrame[cl][2] = didHurtOnFrame[cl][1];
        didHurtOnFrame[cl][1] = didHurtOnFrame[cl][0];
        didHurtOnFrame[cl][0] = didHurtThisFrame[cl];
        didHurtThisFrame[cl] = false;

        // did we shoot a bullet in any of the past few frames?
        didBangOnFrame[cl][2] = didBangOnFrame[cl][1];
        didBangOnFrame[cl][1] = didBangOnFrame[cl][0];
        didBangOnFrame[cl][0] = didBangThisFrame[cl];
        didBangThisFrame[cl] = false;
    }

    // detect trigger teleports
    // squared for optimization
    // 256 * 256
    static int maxTeleDist = 65536;
    if (GetVectorDistance(clpos[cl][0], clpos[cl][1], /* squared for optimization */ true) >= maxTeleDist)
    {
        // reuse this variable
        timeSinceTeled[cl] = GetEngineTime();
    }

    // neither of these tests need fancy checks, so we do them first
    bhopCheck(cl);
    turnbindCheck(cl);

    // we have to do all these annoying checks to make sure we get as few false positives as possible.
    if
    (
        // make sure client is on a team & alive - spec cameras can cause fake angs!
           !IsClientPlaying(cl)
        // ...isn't currently taunting - can cause fake angs!
        || playerTaunting[cl]
        // ...didn't recently spawn - can cause invalid psilent detects
        || engineTime[cl][0] - 1.5 < timeSinceSpawn[cl]
        // ...didn't recently taunt - can (obviously) cause fake angs!
        || engineTime[cl][0] - 1.0 < timeSinceTaunt[cl]
        // ...didn't recently teleport - can cause psilent detects
        || engineTime[cl][0] - 1.0 < timeSinceTeled[cl]
        // don't touch if map or plugin just started - let the server framerate stabilize a bit
        || engineTime[cl][0] - 5.0 < timeSinceMapStart
        // lets wait a bit if we had a server lag spike in the last 5 seconds
        || engineTime[cl][0] - ServerLagWaitLength < timeSinceLagSpikeFor[0]
        // this is just for halloween shit - plenty of halloween effects can and will mess up all of these checks
        // TODO: THIS CAN APPARENTLY BE SPOOFED. CLEAN THIS UP.
        || playerInBadCond[cl] != 0
    )
    {
        return;
    }

    // not really a lag dependant check
    fakeangCheck(cl);

    // dont check cmdnum here but check everything else
    if ( !IsUserLagging(cl, /* checkcmdnum = */ false) )
    {
        //LogMessage("would check cmdnumspikeCheck - >");

        cmdnumspikeCheck(cl);
    }

    // time to wait after player lags before checking single client's OnPlayerRunCmd
    static float PlayerLagWaitLength = 5.0;

    // Give some overlap so that we check BEFORE the lag length expires
    if ( engineTime[cl][0] - ( PlayerLagWaitLength - 1.0 ) < timeSinceLagSpikeFor[cl] )
    {
        IsUserLagging(cl, false);
    }

    // lets also wait a bit if we had a lag spike in the last 5 seconds on this specific client
    if ( engineTime[cl][0] - PlayerLagWaitLength < timeSinceLagSpikeFor[cl] )
    {
        return;
    }

    //LogMessage("would check psilent - >");

/*
    if
    (
        // make sure client doesn't have OUTRAGEOUS ping
        // most cheater fakeping goes up to 800 so tack on 50 just in case
        pingFor[cl] > 850.0
    )
    {
        return;
    }
*/


    if
    (
        // make sure client isnt using a spin bind
        ( buttons & IN_LEFT | buttons & IN_RIGHT )
        // make sure we're not lagging and that cmdnum is saneish
        || IsUserLagging(cl, /* checkcmdnum = */ true)
    )
    // if any of these things are true, don't check angles etc
    {
        return;
    }

    triggerbotCheck(cl);
    aimsnapCheck(cl);
    psilentCheck(cl);

    // THIS IS GOING TO LEAK HANDLES BECAUSE WE WONT ALWAYS GET HERE
    // SHUT UP
    //StopProfiling(prof);
    //float usTime = GetProfilerTime(prof) * 1000.0 * 1000.0;
    //if (usTime >= 30.0)
    //{
    //    LogMessage("%09.3fµs", usTime);
    //}
    //delete prof;

    return;
}

/*
    BHOP DETECTION - using lilac and ssac as reference, this one's better tho
*/
void bhopCheck(int cl)
{
    // don't run this check if cvar is -1
    if (maxBhopDetections == -1)
    {
        return;
    }

    // get movement flags
    // 5x faster than GetEntityFlags!!!
    int flags = GetEntData(cl, Offset_m_fFlags);

    bool noban;
    if (maxBhopDetections == 0)
    {
        noban = true;
    }

    // reset their gravity if it's high!
    if (highGrav[cl])
    {
        SetEntityGravity(cl, 1.0);
        highGrav[cl] = false;
    }

    if
    (
        // last input didn't have a jump
            !(clbuttons[cl][1] & IN_JUMP)
        // player pressed jump
        &&  (clbuttons[cl][0] & IN_JUMP)
        // they were on the ground when they jumped
        &&  (flags & FL_ONGROUND)
    )
    {
        // increment bhops
        bhopDetects[cl]++;

        // print to admins if close to getting banned - or at default bhop amt ( 10 )
        if
        (
            (
                bhopDetects[cl] >= maxBhopDetections
                &&
                !noban
            )
            ||
            (
                bhopDetects[cl] >= 10
                &&
                noban
            )
        )
        {
            int userid = GetClientUserId(cl);
            PrintToImportant("{hotpink}[StAC]{white} Player %N {mediumpurple}bhopped{white}!\nConsecutive detections so far: {palegreen}%i" , cl, bhopDetects[cl]);
            if (bhopDetects[cl] % 5 == 0)
            {
                StacDetectionNotify(userid, "consecutive tick perfect bhops", bhopDetects[cl]);
            }
            StacLogSteam(userid);

            if (bhopDetects[cl] >= maxBhopDetections)
            {
                // punish on maxBhopDetections + 2 (for the extra TWO tick perfect bhops at 8x grav with no warning - no human can do this!)
                if
                (
                    (bhopDetects[cl] >= (maxBhopDetections + 2))
                    &&
                    !noban
                )
                {
                    SetEntityGravity(cl, 1.0);
                    highGrav[cl] = false;
                    char reason[128];
                    Format(reason, sizeof(reason), "%t", "bhopBanMsg", bhopDetects[cl]);
                    char pubreason[256];
                    Format(pubreason, sizeof(pubreason), "%t", "bhopBanAllChat", cl, bhopDetects[cl]);
                    BanUser(userid, reason, pubreason);
                    return;
                }

                // don't run antibhop if cvar is 0
                if (maxBhopDetections > 0)
                {
                    /* ANTIBHOP */
                    // set the player's gravity to 8x.
                    // if idiot cheaters keep holding their spacebar for an extra second and do 2 tick perfect bhops WHILE at 8x gravity...
                    // ...we will catch them autohopping and ban them!
                    SetEntityGravity(cl, 8.0);
                    highGrav[cl] = true;
                }
            }
        }
    }
    else if
    (
        // player didn't press jump
        !(
            clbuttons[cl][0] & IN_JUMP
        )
        // player is on the ground
        &&
        (
            flags & FL_ONGROUND
        )
    )
    {
        // set to -1 to ignore single jumps, we ONLY want to count bhops
        bhopDetects[cl] = -1;
    }
}

/*
    TURN BIND TEST
*/
void turnbindCheck(int cl)
{
    if (maxAllowedTurnSecs == -1.0)
    {
        return;
    }
    if
    (
        clbuttons[cl][0] & IN_LEFT
        ||
        clbuttons[cl][0] & IN_RIGHT
    )
    {
        int userid = GetClientUserId(cl);

        turnTimes[cl]++;
        float turnSec = turnTimes[cl] * tickinterv;
        PrintToImportant("%t", "turnbindAdminMsg", cl, turnSec);
        StacLogSteam(userid);

        if (turnSec < maxAllowedTurnSecs)
        {
            MC_PrintToChat(cl, "%t", "turnbindWarnPlayer");
        }
        else if (turnSec >= maxAllowedTurnSecs)
        {
            StacGeneralPlayerNotify(userid, "Client was kicked for turn binds");
            KickClient(cl, "%t", "turnbindKickMsg");
            MC_PrintToChatAll("%t", "turnbindAllChat", cl);
            StacLog("%t", "turnbindAllChat", cl);
        }
    }
}

/*
    EYE ANGLES TEST
    if clients are outside of allowed angles in tf2, which are
      +/- 89.0 x (up / down)
      +/- 180 y (left / right, but we don't check this atm because there's things that naturally fuck up y angles, such as taunts)
      +/- 50 z (roll / tilt)
    while they are not in spec & on a map camera, we should log it.
    we would fix them but cheaters can just ignore server-enforced viewangle changes so there's no point

    these bounds were lifted from lilac. Thanks lilac.
    lilac patches roll, we do not, i think it (screen shake) is an important part of tf2,
    jtanz says that lmaobox can abuse roll so it should just be removed. i think both opinions are fine
*/
void fakeangCheck(int cl)
{
    // don't bother checking if fakeang detection is off
    if (maxFakeAngDetections == -1)
    {
        return;
    }
    if
    (
        FloatAbs(clangles[cl][0][PITCH]) > 89.00
        ||
        FloatAbs(clangles[cl][0][ROLL ]) > 50.00
    )
    {
        int userid = GetClientUserId(cl);

        fakeAngDetects[cl]++;
        PrintToImportant
        (
            "{hotpink}[StAC]{white} Player %N has {mediumpurple}invalid eye angles{white}!\nCurrent angles: {mediumpurple}%.2f %.2f %.2f{white}.\nDetections so far: {palegreen}%i",
            cl,
            clangles[cl][0][PITCH],
            clangles[cl][0][YAW  ],
            clangles[cl][0][ROLL ],
            fakeAngDetects[cl]
        );
        StacLogSteam(userid);
        if (fakeAngDetects[cl] == 1 || fakeAngDetects[cl] % 5 == 0)
        {
            StacDetectionNotify(userid, "fake angles", fakeAngDetects[cl]);
        }
        if (fakeAngDetects[cl] >= maxFakeAngDetections && maxFakeAngDetections > 0)
        {
            char reason[128];
            Format(reason, sizeof(reason), "%t", "fakeangBanMsg", fakeAngDetects[cl]);
            char pubreason[256];
            Format(pubreason, sizeof(pubreason), "%t", "fakeangBanAllChat", cl, fakeAngDetects[cl]);
            BanUser(userid, reason, pubreason);
        }
    }
}

/*
    CMDNUM SPIKE TEST - heavily modified from SSAC
    this is for detecting when cheats "skip ahead" their cmdnum so they can fire a "perfect shot" aka a shot with no spread
    funnily enough, it actually DOESN'T change where their bullet goes, it's just a client side visual effect with decals
*/
void cmdnumspikeCheck(int cl)
{
    if (maxCmdnumDetections == -1)
    {
        return;
    }

    int spikeamt = clcmdnum[cl][0] - clcmdnum[cl][1];
    // https://github.com/sapphonie/StAC-tf2/issues/74
    if (spikeamt >= 32 || spikeamt < 0)
    {
        int userid = GetClientUserId(cl);

        char heldWeapon[256];
        GetClientWeapon(cl, heldWeapon, sizeof(heldWeapon));

        cmdnumSpikeDetects[cl]++;
        PrintToImportant
        (
            "{hotpink}[StAC]{white} Cmdnum SPIKE of {yellow}%i{white} on %N.\nDetections so far: {palegreen}%i{white}.",
            spikeamt,
            cl,
            cmdnumSpikeDetects[cl]
        );
        StacLogSteam(userid);
        StacLogNetData(userid);
        StacLogCmdnums(userid);
        StacLogTickcounts(userid);
        StacLog("Held weapon: %s", heldWeapon);

        if (cmdnumSpikeDetects[cl] % 5 == 0)
        {
            StacDetectionNotify(userid, "cmdnum spike", cmdnumSpikeDetects[cl]);
        }

        // punish if we reach limit set by cvar
        if (cmdnumSpikeDetects[cl] >= maxCmdnumDetections && maxCmdnumDetections > 0)
        {
            char reason[128];
            Format(reason, sizeof(reason), "%t", "cmdnumSpikesBanMsg", cmdnumSpikeDetects[cl]);
            char pubreason[256];
            Format(pubreason, sizeof(pubreason), "%t", "cmdnumSpikesBanAllChat", cl, cmdnumSpikeDetects[cl]);
            BanUser(userid, reason, pubreason);
        }
    }
}

/*
    SILENT AIM DETECTION
    silent aim (in this context) works by aimbotting for 1 tick and then snapping your viewangle back to what it was
    example snap:
        L 03/25/2020 - 06:03:50: [stac.smx] [StAC] pSilent detection: angles0  angles: x 5.120096 y 9.763162
        L 03/25/2020 - 06:03:50: [stac.smx] [StAC] pSilent detection: angles1  angles: x 1.635611 y 12.876886
        L 03/25/2020 - 06:03:50: [stac.smx] [StAC] pSilent detection: angles2  angles: x 5.120096 y 9.763162
    we can just look for these snaps and log them as detections!
    note that this won't detect some snaps when a player is moving their strafe keys and mouse @ the same time while they are aimlocking.

    we have to do EXTRA checks because a lot of things can fuck up silent aim detection
    make sure ticks are sequential, hopefully avoid laggy players
    example real detection:

    [StAC] pSilent / NoRecoil detection of 5.20° on <user>.
    Detections so far: 15
    User Net Info: 0.00% loss, 24.10% choke, 66.22 ms ping
     clcmdnum[0]: 61167
     clcmdnum[1]: 61166
     clcmdnum[2]: 61165
     angles0: x 8.82 y 127.68
     angles1: x 5.38 y 131.60
     angles2: x 8.82 y 127.68
*/

// check angle diff from clangles[cl][1] to clangles[cl][0] and clangles[cl][2] , count if they "match" up to an epsilon of 1.0 deg (ish?)
// my foolishly =='ing floats must unfortunately come to an end

// https://bitbashing.io/comparing-floats.html
// DON'T use prec values above ~2, even ~1 was giving me weird issues
bool floatcmpreal( float a, float b, float precision = 0.001 )
{
    return FloatAbs( a - b ) <= precision;
}

void psilentCheck(int cl)
{
    // don't run this check if silent aim cvar is -1
    if (maxPsilentDetections == -1)
    {
        return;
    }

    // make sure we've been attacking in this frame or the last
    if ( !(clbuttons[cl][0] & IN_ATTACK) && !(clbuttons[cl][1] & IN_ATTACK) )
    {
        return;
    }

    static float pSilentEpsilon = 0.1;
    // get difference between angles - used for psilent
    float aDiffReal;
    bool detect;

    if
    (
        // so the current and 2nd previous angles match...
        (
            floatcmpreal(clangles[cl][0][PITCH], clangles[cl][2][PITCH], pSilentEpsilon)
            &&
            floatcmpreal(clangles[cl][0][ YAW ], clangles[cl][2][ YAW ], pSilentEpsilon)
        )
        &&
        // BUT the 1st previous (in between) angle doesnt?
        (
               !floatcmpreal(clangles[cl][1][PITCH], clangles[cl][0][PITCH], pSilentEpsilon)
            && !floatcmpreal(clangles[cl][1][ YAW ], clangles[cl][0][ YAW ], pSilentEpsilon)
            && !floatcmpreal(clangles[cl][1][PITCH], clangles[cl][2][PITCH], pSilentEpsilon)
            && !floatcmpreal(clangles[cl][1][ YAW ], clangles[cl][2][ YAW ], pSilentEpsilon)
        )
    )
    {
        detect = true;
        aDiffReal = NormalizeAngleDiff(CalcAngDeg(clangles[cl][0], clangles[cl][1]));
    }
    //  ok - lets make sure there's a difference of at least 1 degree on either axis to avoid most fake detections
    //  these are probably caused by packets arriving out of order but i'm not a fucking network engineer (yet) so idk
    //  examples of fake detections we want to avoid:
    //      03/25/2020 - 18:18:11: [stac.smx] [StAC] pSilent detection on [redacted]: curang angles: x 14.871331 y 154.979812
    //      03/25/2020 - 18:18:11: [stac.smx] [StAC] pSilent detection on [redacted]: prev1  angles: x 14.901910 y 155.010391
    //      03/25/2020 - 18:18:11: [stac.smx] [StAC] pSilent detection on [redacted]: prev2  angles: x 14.871331 y 154.979812
    //  and
    //      03/25/2020 - 22:16:36: [stac.smx] [StAC] pSilent detection on [redacted2]: curang angles: x 21.516006 y -140.723709
    //      03/25/2020 - 22:16:36: [stac.smx] [StAC] pSilent detection on [redacted2]: prev1  angles: x 21.560007 y -140.943710
    //      03/25/2020 - 22:16:36: [stac.smx] [StAC] pSilent detection on [redacted2]: prev2  angles: x 21.516006 y -140.723709
    //  doing this might make it harder to detect legitcheaters but like. legitcheating in a 12 yr old dead game OMEGALUL who fucking cares
    if (!detect || aDiffReal < 1.0)
    {
        return;
    }
    int userid = GetClientUserId(cl);
    pSilentDetects[cl]++;
    // have this detection expire in 30 minutes
    CreateTimer(1800.0, Timer_decr_pSilent, userid, TIMER_FLAG_NO_MAPCHANGE);
    // first detection is LIKELY bullshit
    if (pSilentDetects[cl] > 0)
    {
        // only print a bit in chat, rest goes to console (stv and admin and also the stac log)
        PrintToImportant
        (
            "\
            {hotpink}[StAC]{white} SilentAim detection of {yellow}%.2f{white}° on %N.\
            \nDetections so far: {palegreen}%i{white} norecoil = {plum}%s",
            aDiffReal, cl,
            pSilentDetects[cl], aDiffReal <= 3.0 ? "yes" : "no"
        );
        StacLogSteam(userid);
        StacLogNetData(userid);
        StacLogAngles(userid);
        StacLogCmdnums(userid);
        StacLogTickcounts(userid);
        StacLogMouse(userid);
        if (AIMPLOTTER)
        {
            ServerCommand("sm_aimplot #%i on", userid);
        }
        if (pSilentDetects[cl] % 5 == 0)
        {
            StacDetectionNotify(userid, "psilent", pSilentDetects[cl]);
        }
        // BAN USER if they trigger too many detections
        if (pSilentDetects[cl] >= maxPsilentDetections && maxPsilentDetections > 0)
        {
            char reason[128];
            Format(reason, sizeof(reason), "%t", "pSilentBanMsg", pSilentDetects[cl]);
            char pubreason[256];
            Format(pubreason, sizeof(pubreason), "%t", "pSilentBanAllChat", cl, pSilentDetects[cl]);
            BanUser(userid, reason, pubreason);
        }
    }
}

/*
    AIMSNAP DETECTION - BETA

    Alright, here's how this works.

    If we try to just detect one frame snaps and nothing else, users can just crank up their sens,
    and wave their mouse around and get detects. so what we do is this:

    if a user has a snap of more than 20 degrees, and that snap is surrounded on one or both sides by "noise delta" of LESS than 5 degrees
    ...that counts as an aimsnap. this will catch cheaters, unless they wave their mouse around wildly, making the game miserable to play
    AND obvious that they're avoiding the anticheat.

*/
void aimsnapCheck(int cl)
{
    // only check if we have this check enabled
    if (maxAimsnapDetections == -1)
    {
        return;
    }

    if
    (
        // for some reason this just does not behave well in mvm
        MVM
        ||
        // only check if we pressed attack recently
        !(
               clbuttons[cl][0] & IN_ATTACK
            || clbuttons[cl][1] & IN_ATTACK
            || clbuttons[cl][2] & IN_ATTACK
        )
    )
    {
        return;
    }

    // only check if we actually did hitscan dmg in the current frame
    // thinking about removing this...
    if (!didHurtOnFrame[cl][1] || !didBangOnFrame[cl][1])
    {
        return;
    }

    float aDiff[4];
    aDiff[0] = NormalizeAngleDiff( CalcAngDeg( clangles[cl][0], clangles[cl][1] ) );
    aDiff[1] = NormalizeAngleDiff( CalcAngDeg( clangles[cl][1], clangles[cl][2] ) );
    aDiff[2] = NormalizeAngleDiff( CalcAngDeg( clangles[cl][2], clangles[cl][3] ) );
    aDiff[3] = NormalizeAngleDiff( CalcAngDeg( clangles[cl][3], clangles[cl][4] ) );

    // example values of a snap:
    // 0.000000, 91.355995, 0.000000, 0.000000
    // 0.018540, 0.000000, 91.355995, 0.000000

    static float snapsize  = 20.0;
    static float noisesize = 1.0;

    int aDiffToUse = -1;

    // commented so we can make sure we have one or more noise buffers
    //if
    //(
    //       aDiff[0] > snapsize
    //    && aDiff[1] < noisesize
    //    && aDiff[2] < noisesize
    //    && aDiff[3] < noisesize
    //)
    //{
    //    aDiffToUse = 0;
    //}
    if
    (
           aDiff[0] < noisesize
        && aDiff[1] > snapsize
        && aDiff[2] < noisesize
        && aDiff[3] < noisesize
    )
    {
        aDiffToUse = 1;
    }
    if
    (
           aDiff[0] < noisesize
        && aDiff[1] < noisesize
        && aDiff[2] > snapsize
        && aDiff[3] < noisesize
    )
    {
        aDiffToUse = 2;
    }
    //else if
    //(
    //       aDiff[0] < noisesize
    //    && aDiff[1] < noisesize
    //    && aDiff[2] < noisesize
    //    && aDiff[3] > snapsize
    //)
    //{
    //    aDiffToUse = 3;
    //}

    if (aDiffToUse == -1)
    {
        return;
    }

    // we got one!
    float aDiffReal = aDiff[aDiffToUse];

    int userid = GetClientUserId(cl);

    // increment aimsnap detects
    aimsnapDetects[cl]++;
    // have this detection expire in 30 minutes
    CreateTimer(1800.0, Timer_decr_aimsnaps, userid, TIMER_FLAG_NO_MAPCHANGE);
    // first detection is likely bullshit
    if (aimsnapDetects[cl] > 0)
    {
        PrintToImportant
        (
            "{hotpink}[StAC]{white} Aimsnap detection of {yellow}%.2f{white}° on %N.\nDetections so far: {palegreen}%i{white}.",
            aDiffReal,
            cl,
            aimsnapDetects[cl]
        );
        StacLogSteam(userid);
        StacLogNetData(userid);
        StacLogAngles(userid);
        StacLogCmdnums(userid);
        StacLogTickcounts(userid);
        StacLogMouse(userid);
        StacLog
        (
            "\nAngle deltas:\n0 %f\n1 %f\n2 %f\n3 %f\n",
            aDiff[0],
            aDiff[1],
            aDiff[2],
            aDiff[3]
        );

        if (AIMPLOTTER)
        {
            ServerCommand("sm_aimplot #%i on", userid);
        }

        if (aimsnapDetects[cl] % 5 == 0)
        {
            StacDetectionNotify(userid, "aimsnap", aimsnapDetects[cl]);
        }

        // BAN USER if they trigger too many detections
        if (aimsnapDetects[cl] >= maxAimsnapDetections && maxAimsnapDetections > 0)
        {
            char reason[128];
            Format(reason, sizeof(reason), "%t", "AimsnapBanMsg", aimsnapDetects[cl]);
            char pubreason[256];
            Format(pubreason, sizeof(pubreason), "%t", "AimsnapBanAllChat", cl, aimsnapDetects[cl]);
            BanUser(userid, reason, pubreason);
        }
    }
}

/*
    TRIGGERBOT DETECTION
*/
void triggerbotCheck(int cl)
{
    // don't run if cvar is -1 or if wait is enabled on this server
    if (maxTbotDetections == -1 || waitStatus)
    {
        return;
    }

    int attack = 0;

    // grab single tick +attack inputs - this checks for the following pattern:
    // frame before last    //
    // last frame           // IN_ATTACK
    // current frame        //
    if
    (
        !(clbuttons[cl][2] & IN_ATTACK)
        &&
        (clbuttons[cl][1] & IN_ATTACK)
        &&
        !(clbuttons[cl][0] & IN_ATTACK)
    )
    {
        attack = 1;
    }
    // grab single tick +attack2 inputs - pyro airblast, demo det, etc
    // this checks for the following pattern:
    // frame before last    //
    // last frame           // IN_ATTACK2
    // current frame        //

    else if
    (
        !(clbuttons[cl][2] & IN_ATTACK2)
        &&
        (clbuttons[cl][1] & IN_ATTACK2)
        &&
        !(clbuttons[cl][0] & IN_ATTACK2)
    )
    {
        attack = 2;
    }

    if
    (
        // did not dmg on this tick
        !didHurtOnFrame[cl][0]
        ||
        // not a single tick input
        attack == 0
    )
    {
        return;
    }

    int userid = GetClientUserId(cl);

    tbotDetects[cl]++;
    // have this detection expire in 30 minutes
    CreateTimer(1800.0, Timer_decr_tbot, userid, TIMER_FLAG_NO_MAPCHANGE);

    if (tbotDetects[cl] > 0)
    {
        PrintToImportant
        (
            "{hotpink}[StAC]{white} Triggerbot detection on %N.\nDetections so far: {palegreen}%i{white}. Type: +attack{blue}%i",
            cl,
            tbotDetects[cl],
            attack
        );
        StacLogSteam(userid);
        StacLogNetData(userid);
        StacLogAngles(userid);
        StacLogCmdnums(userid);
        StacLogTickcounts(userid);
        StacLogMouse(userid);
        StacLog
        (
            "Weapon used: %s",
            hurtWeapon[cl]
        );

        if (AIMPLOTTER)
        {
            ServerCommand("sm_aimplot #%i on", userid);
        }
        if (tbotDetects[cl] % 5 == 0)
        {
            StacDetectionNotify(userid, "triggerbot", tbotDetects[cl]);
        }
        // BAN USER if they trigger too many detections
        if (tbotDetects[cl] >= maxTbotDetections && maxTbotDetections > 0)
        {
            char reason[128];
            Format(reason, sizeof(reason), "%t", "tbotBanMsg", tbotDetects[cl]);
            char pubreason[256];
            Format(pubreason, sizeof(pubreason), "%t", "tbotBanAllChat", cl, tbotDetects[cl]);
            BanUser(userid, reason, pubreason);
        }
    }
}

/********** OnPlayerRunCmd based helper functions **********/


// TODO: we NEED to make this overlap
bool IsUserLagging(int cl, bool checkcmdnum = true)
{
    /*
    if ( lossFor[cl] >= 10.0 )
    {
        timeSinceLagSpikeFor[cl] = engineTime[cl][0];
        return true;
    }
    */

    // check if we have sequential cmdnums
    if ( checkcmdnum && !isCmdnumSequential(cl) )
    {
        timeSinceLagSpikeFor[cl] = engineTime[cl][0];
        return true;
    }

    // TIME_TO_TICKS
    float ratio = timeSinceLastRecvFor[cl][0] / tickinterv;
    if ( ratio >= 6.0 || ratio < 0.0 )
    {
        //LogMessage("ratio = %f", ratio );
        //LogMessage("tps = %i", tickspersec[cl] );
        timeSinceLagSpikeFor[cl] = engineTime[cl][0];
        return true;
    }

    static float maxPingDiff = 15.0;
    float nowdiff = pingFor[cl] - avgPingFor[cl];
    // LogMessage("%f / avg %f / jitter %f" , nowdiff, avgPingFor[cl], pingFor[cl]);
    // if jitter ping is 10ms less than avg...
    if ( nowdiff >= maxPingDiff || nowdiff <= -maxPingDiff )
    {

        timeSinceLagSpikeFor[cl] = engineTime[cl][0];

        //LogMessage("pingdiff = %f", maxPingDiff );
        return true;
    }

    return false;
}

// calc distance between snaps in degrees
float CalcAngDeg(float array1[3], float array2[3])
{
    // ignore roll
    array1[2] = 0.0;
    array2[2] = 0.0;
    return SquareRoot(GetVectorDistance(array1, array2, true));
}

float NormalizeAngleDiff(float aDiff)
{
    if (aDiff > 180.0)
    {
        aDiff = FloatAbs(aDiff - 360.0);
    }
    return aDiff;
}

bool HasValidAngles(int cl)
{
    if
    (
        // ignore weird angle resets in mge / dm && ignore laggy players
           IsZeroVector(clangles[cl][0])
        || IsZeroVector(clangles[cl][1])
        || IsZeroVector(clangles[cl][2])
        || IsZeroVector(clangles[cl][3])
        || IsZeroVector(clangles[cl][4])
    )
    {
        return false;
    }
    return true;
}

bool isCmdnumSequential(int cl)
{
    if
    (
           clcmdnum[cl][0] == clcmdnum[cl][1] + 1
        && clcmdnum[cl][1] == clcmdnum[cl][2] + 1
        && clcmdnum[cl][2] == clcmdnum[cl][3] + 1
        && clcmdnum[cl][3] == clcmdnum[cl][4] + 1
    )
    {
        return true;
    }
    return false;
}

// check if the current cmdnum is greater than the last value etc
/*
bool isCmdnumInOrder(int cl)
{
    if (clcmdnum[cl][0] > clcmdnum[cl][1] > clcmdnum[cl][2] > clcmdnum[cl][3] > clcmdnum[cl][4])
    {
        return true;
    }
    return false;
}

bool isTickcountInOrder(int cl)
{
    if (cltickcount[cl][0] > cltickcount[cl][1] > cltickcount[cl][2] > cltickcount[cl][3] > cltickcount[cl][4])
    {
        return true;
    }
    return false;
}

bool isTickcountRepeated(int cl)
{
    if
    (
           cltickcount[cl][0] == cltickcount[cl][1]
        && cltickcount[cl][1] == cltickcount[cl][2]
        && cltickcount[cl][2] == cltickcount[cl][3]
        && cltickcount[cl][3] == cltickcount[cl][4]
    )
    {
        return true;
    }
    return false;
}
*/

/********** DETECTION FORGIVENESS TIMERS **********/

Action Timer_decr_aimsnaps(Handle timer, any userid)
{
    int cl = GetClientOfUserId(userid);

    if (IsValidClient(cl))
    {
        if (aimsnapDetects[cl] > -1)
        {
            aimsnapDetects[cl]--;
        }
        if (aimsnapDetects[cl] <= 0)
        {
            if (AIMPLOTTER)
            {
                ServerCommand("sm_aimplot #%i off", userid);
            }
        }
    }

    return Plugin_Continue;
}

Action Timer_decr_pSilent(Handle timer, any userid)
{
    int cl = GetClientOfUserId(userid);

    if (IsValidClient(cl))
    {
        if (pSilentDetects[cl] > -1)
        {
            pSilentDetects[cl]--;
        }
        if (pSilentDetects[cl] <= 0)
        {
            if (AIMPLOTTER)
            {
                ServerCommand("sm_aimplot #%i off", userid);
            }
        }
    }

    return Plugin_Continue;
}

Action Timer_decr_tbot(Handle timer, any userid)
{
    int cl = GetClientOfUserId(userid);

    if (IsValidClient(cl))
    {
        if (tbotDetects[cl] > -1)
        {
            tbotDetects[cl]--;
        }
        if (tbotDetects[cl] <= 0)
        {
            if (AIMPLOTTER)
            {
                ServerCommand("sm_aimplot #%i off", userid);
            }
        }
    }

    return Plugin_Continue;
}

/*
void point_worldtext_TODO(int cl)
{
    //if ( !pointWorldTextEnts[cl][0] || !pointWorldTextEnts[cl][1] || !pointWorldTextEnts[cl][2] )
    //{
    //    return;
    //}
    TODO point_worldtext

    put this in a func
    // this is so ugly lol
    static char RareButtonNames[][] =
    {
        "",
        "",
        "",
        "",
        "",
        "",
        "CANCEL",
        "LEFT",
        "RIGHT",
        "",
        "",
        "",
        "RUN",
        "",
        "ALT1",
        "ALT2",
        "SCORE",
        "SPEED",
        "WALK",
        "ZOOM",
        "WEAPON1",
        "WEAPON2",
        "BULLRUSH",
        "GRENADE1",
        "GRENADE2",
        ""
    };

    int buttons = clbuttons[cl][0];

    char fwd    [4] = "_";
    if (buttons & IN_FORWARD)
    {
        fwd = "^";
    }

    char back   [4] = "_";
    if (buttons & IN_BACK)
    {
        back = "v";
    }

    char left   [4] = "_";
    if (buttons & IN_MOVELEFT)
    {
        left = "<";
    }

    char right  [4] = "_";
    if (buttons & IN_MOVERIGHT)
    {
        right = ">";
    }

    char m1     [4] = "_";
    if (buttons & IN_ATTACK)
    {
        m1 = "1";
    }

    char m2     [4] = "_";
    if (buttons & IN_ATTACK2)
    {
        m2 = "2";
    }

    char m3     [4] = "_";
    if (buttons & IN_ATTACK3)
    {
        m3 = "3";
    }

    char jump   [6] = "____";
    if (buttons & IN_JUMP)
    {
        jump = "JUMP";
    }

    char duck   [6] = "____";
    if (buttons & IN_DUCK)
    {
        duck = "DUCK";
    }

    char reload [4] = "_";
    if (buttons & IN_RELOAD)
    {
        reload = "R";
    }
    char use [4] = "_";
    if (buttons & IN_USE)
    {
        use = "U";
    }

    char strButtons[512];
    for (int i = 0; i < sizeof(RareButtonNames); i++)
    {
        if (buttons & (1 << i))
        {
            Format(strButtons, sizeof(strButtons), "%s %s", strButtons, RareButtonNames[i]);
        }
    }
    TrimString(strButtons);
    int userid = GetClientUserId(cl);

    char msg[2048];
    Format(msg,  sizeof(msg),
        "\
        \nOnPlayerRunCmd Info:\
        \n %i cmdnum\
        \n %i tickcount\
        \n common buttons:\
        \n  %c %c %c\
        \n  %c %c %c    %c %c %c\
        \n  %s    %s\
        \n other buttons:\
        \n  %s\
        \n buttons int\
        \n  %i\
        \n mouse\
        \n x %i\
        \n y %i\
        \n cl angs\
        \n x %.2f \
        \n y %.2f \
        \n z %.2f \
        ",
        clcmdnum[cl][0],
        cltickcount[cl][0],
        use,  fwd, reload,
        left, back, right,    m1, m2, m3,
        jump, duck,
        IsActuallyNullString(strButtons) ? "N/A" : strButtons,
        clbuttons[cl][0],
        clmouse[cl][0], clmouse[cl][1],
        clangles[cl][0][0], clangles[cl][0][1], clangles[cl][0][2]
    );
    DispatchKeyValue        (pointWorldTextEnts[cl][0], "message", msg);
    TeleportEntity          (pointWorldTextEnts[cl][0], { 255.0, 255.0, 255.0 }, NULL_VECTOR, NULL_VECTOR);

    Format(msg,  sizeof(msg),
        "\
        \nMisc Info:\
        \n Approx client cmdrate: ≈%i cmd/sec\
        \n Approx server tickrate: ≈%i tick/sec\
        \n Failing lag check? %s\
        \n HasValidAngles? %s\
        \n SequentialCmdnum? %s\
        \n OrderedTickcount? %s\
        ",
        tickspersec[cl],
        tickspersec[0],
        IsUserLagging(userid) ? "yes" : "no",
        HasValidAngles(cl) ? "yes" : "no",
        isCmdnumSequential(userid) ? "yes" : "no",
        isTickcountInOrder(userid) ? "yes" : "no"
    );
    DispatchKeyValue        (pointWorldTextEnts[cl][1], "message", msg);


    Format(msg,  sizeof(msg),
        "\
        \nClient: %N\
        \n Index: %i\
        \n Userid: %i\
        \n Status: %s\
        \n Connected for: %.0fs\
        \n\
        \nNetwork:\
        \n %.2f ms ping\
        \n %.2f loss\
        \n %.2f inchoke\
        \n %.2f outchoke\
        \n %.2f totalchoke\
        \n %.2f kbps rate\
        \n %.2f pps rate\
        ",
        cl,
        cl,
        GetClientUserId(cl),
        IsPlayerAlive(cl) ? "alive" : "dead",
        GetClientTime(cl),
        pingFor[cl],
        lossFor[cl],
        inchokeFor[cl],
        outchokeFor[cl],
        chokeFor[cl],
        rateFor[cl],
        ppsFor[cl]
    );
    DispatchKeyValue        (pointWorldTextEnts[cl][2], "message", msg);

}
*/
