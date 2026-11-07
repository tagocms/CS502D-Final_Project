---@meta

---@alias JumperFinder 'ASTAR'|'DIJKSTRA'|'THETASTAR'|'BFS'|'DFS'|'JPS'
---@alias JumperWalkable integer|string|fun(value: any): boolean

---@class JumperNode
---@field getX fun(self: JumperNode): integer
---@field getY fun(self: JumperNode): integer
---@field getPos fun(self: JumperNode): integer, integer

---@class JumperPath
---@field iter fun(self: JumperPath): fun(): JumperNode?, integer?
---@field fill fun(self: JumperPath): JumperPath
---@field getLength fun(self: JumperPath): number

---@class Grid
---@field isWalkableAt fun(self: Grid, x: integer, y: integer, walkable?: JumperWalkable, clearance?: integer): boolean
---@field getWidth fun(self: Grid): integer
---@field getHeight fun(self: Grid): integer
---@field getNodeAt fun(self: Grid, x: integer, y: integer): JumperNode?

---@class Pathfinder
---@field getPath fun(self: Pathfinder, startX: integer, startY: integer, endX: integer, endY: integer, clearance?: integer): JumperPath?
---@field setMode fun(self: Pathfinder, mode: 'DIAGONAL'|'ORTHOGONAL'): Pathfinder
---@field getMode fun(self: Pathfinder): string
---@field setWalkable fun(self: Pathfinder, walkable: JumperWalkable)
---@field getGrid fun(self: Pathfinder): Grid
