require 'class-war', 'https://github.com/toxidroma/class-war'
    --provides PLYCLASS

class IMMERSIVE extends PLYCLASS
    PostPlayerDeath: =>
        ragdoll = @Player\GetRagdollEntity!
        ragdoll\Remove! if IsValid ragdoll