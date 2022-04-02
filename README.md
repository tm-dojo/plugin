# TMDojo Plugin

This is the Openplanet plugin for TMDojo.

It records telemetry data when playing the game, which gets uploaded to our API.

The data is obtained using [Openplanet's CSceneVehicleVisState](https://next.openplanet.nl/Scene/CSceneVehicleVisState).

## Data format

The plugin creates a "sample" 60 times a second.
The samples are added into a binary buffer.
Each sample contains 23 values for a total of 112 bytes.

The values are stored in the following order:


| Name                        | Type        | Size        |
| --------------------------- | ----------- | ----------- |
| currentRaceTime             | `Int32`     | 4 bytes     |
| position.x                  | `Float32`   | 4 bytes     |
| position.y                  | `Float32`   | 4 bytes     |
| position.z                  | `Float32`   | 4 bytes     |
| velocity.x                  | `Float32`   | 4 bytes     |
| velocity.y                  | `Float32`   | 4 bytes     |
| velocity.z                  | `Float32`   | 4 bytes     |
| speed                       | `Float32`   | 4 bytes     |
| inputSteer                  | `Float32`   | 4 bytes     |
| wheelAngle                  | `Float32`   | 4 bytes     |
| gasAndBrake                 | `Int32`     | 4 bytes     |
| engineRpm                   | `Float32`   | 4 bytes     |
| engineCurGear               | `Int32`     | 4 bytes     |
| up.x                        | `Float32`   | 4 bytes     |
| up.y                        | `Float32`   | 4 bytes     |
| up.z                        | `Float32`   | 4 bytes     |
| dir.x                       | `Float32`   | 4 bytes     |
| dir.y                       | `Float32`   | 4 bytes     |
| dir.z                       | `Float32`   | 4 bytes     |
| fLGroundContactMaterial     | `Int8`      | 1 bytes     |
| fLSlipCoef                  | `Float32`   | 4 bytes     |
| fLDamperLen                 | `Float32`   | 4 bytes     |
| fRGroundContactMaterial     | `Int8`      | 1 bytes     |
| fRSlipCoef                  | `Float32`   | 4 bytes     |
| fRDamperLen                 | `Float32`   | 4 bytes     |
| rLGroundContactMaterial     | `Int8`      | 1 bytes     |
| rLSlipCoef                  | `Float32`   | 4 bytes     |
| rLDamperLen                 | `Float32`   | 4 bytes     |
| rRGroundContactMaterial     | `Int8`      | 1 bytes     |
| rRSlipCoef                  | `Float32`   | 4 bytes     |
| rRDamperLen                 | `Float32`   | 4 bytes     |

![Debug Mode](https://i.imgur.com/Gf7gsul.png)